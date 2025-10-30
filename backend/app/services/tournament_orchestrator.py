from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc, asc
from fastapi import HTTPException

from app.models.tournament import Tournament, TournamentStatus
from app.models.tournament_phase import TournamentPhase, PhaseStatus
from app.models.tournament_participant import TournamentParticipant
from app.models.pool import RafflePool

class TournamentOrchestrator:
    """
    Orchestratore centrale per la gestione automatizzata dei tornei.
    Gestisce:
    - Conversione pool → torneo quando raggiunge il massimo
    - Avvio automatico fasi programmate
    - Eliminazioni alla scadenza delle fasi
    - Progressione alle fasi successive
    - Completamento tornei e assegnazione premi
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def convert_pool_to_tournament(
        self,
        pool_id: str,
        tournament_config: Dict[str, Any]
    ) -> Tournament:
        """Converte un pool FULL in un torneo programmato"""
        
        # Verifica che il pool sia idoneo
        pool = await self.db.get(RafflePool, pool_id)
        if not pool:
            raise HTTPException(status_code=404, detail="Pool not found")
        
        if pool.state != "FULL":
            raise HTTPException(
                status_code=400, 
                detail="Pool must be FULL to convert to tournament"
            )

        # Crea il torneo
        tournament = Tournament(
            pool_id=pool_id,
            title=tournament_config['title'],
            description=tournament_config.get('description'),
            total_phases=len(tournament_config['phases']),
            scheduled_start_at=tournament_config.get('scheduled_start')
        )
        
        self.db.add(tournament)
        await self.db.flush()  # Per ottenere l'ID

        # Crea le fasi
        for i, phase_config in enumerate(tournament_config['phases']):
            phase = TournamentPhase(
                tournament_id=tournament.id,
                phase_number=i + 1,
                game_id=phase_config['game_id'],
                level_id=phase_config.get('level_id'),
                title=phase_config.get('title', f"Phase {i + 1}"),
                description=phase_config.get('description'),
                duration_hours=phase_config.get('duration_hours', 72),
                elimination_rule=phase_config.get('elimination_rule', {
                    'type': 'top_percentage',
                    'value': 50
                }),
                min_score=phase_config.get('min_score'),
                max_time_seconds=phase_config.get('max_time_seconds')
            )
            self.db.add(phase)

        # Aggiorna stato pool
        pool.state = "TOURNAMENT_READY"
        
        await self.db.commit()
        await self.db.refresh(tournament)
        return tournament

    async def check_phase_deadlines(self) -> List[TournamentPhase]:
        """
        Cron job principale: controlla tutte le fasi scadute e attiva eliminazioni.
        Da chiamare ogni ora via scheduler.
        """
        
        # Trova fasi attive scadute
        stmt = select(TournamentPhase).where(
            and_(
                TournamentPhase.status == PhaseStatus.ACTIVE,
                TournamentPhase.deadline_at <= datetime.utcnow()
            )
        )
        result = await self.db.execute(stmt)
        expired_phases = result.scalars().all()

        processed_phases = []
        for phase in expired_phases:
            await self.process_phase_elimination(phase)
            await self.setup_next_phase_or_complete_tournament(phase.tournament)
            processed_phases.append(phase)

        return processed_phases

    async def process_phase_elimination(self, phase: TournamentPhase):
        """Applica le regole di eliminazione per una fase scaduta"""
        
        # Ottieni tutti i partecipanti della fase
        stmt = select(TournamentParticipant).where(
            TournamentParticipant.phase_id == phase.id
        ).order_by(
            desc(TournamentParticipant.best_score),
            asc(TournamentParticipant.best_time_seconds)
        )
        result = await self.db.execute(stmt)
        participants = result.scalars().all()

        if not participants:
            phase.status = PhaseStatus.COMPLETED
            await self.db.commit()
            return

        # Applica regole eliminazione
        qualified_participants = self._apply_elimination_rules(participants, phase)
        
        # Aggiorna stato partecipanti
        for participant in participants:
            if participant in qualified_participants:
                participant.qualified = True
                participant.qualified_at = datetime.utcnow()
            else:
                participant.qualified = False
                participant.eliminated_at = datetime.utcnow()

        # Aggiorna statistiche fase
        phase.status = PhaseStatus.COMPLETED
        phase.qualified_count = len(qualified_participants)
        
        await self.db.commit()

    def _apply_elimination_rules(
        self, 
        participants: List[TournamentParticipant], 
        phase: TournamentPhase
    ) -> List[TournamentParticipant]:
        """Applica le regole di eliminazione specifiche della fase"""
        
        rule = phase.elimination_rule or {'type': 'top_percentage', 'value': 50}
        rule_type = rule.get('type')

        if rule_type == 'top_percentage':
            percentage = rule.get('value', 50)
            qualified_count = max(1, int(len(participants) * percentage / 100))
            return participants[:qualified_count]
        
        elif rule_type == 'min_score':
            min_score = rule.get('value', 0)
            return [p for p in participants if p.best_score >= min_score]
        
        elif rule_type == 'max_time':
            max_time = rule.get('value', float('inf'))
            return [p for p in participants if p.best_time_seconds <= max_time]
        
        elif rule_type == 'combined':
            # Prima filtra per punteggio minimo, poi prendi top N% per tempo
            min_score = rule.get('min_score', 0)
            score_qualified = [p for p in participants if p.best_score >= min_score]
            
            if not score_qualified:
                return []
                
            percentage = rule.get('time_percentage', 50)
            time_qualified_count = max(1, int(len(score_qualified) * percentage / 100))
            
            # Riordina per tempo tra quelli che hanno passato il punteggio
            score_qualified.sort(key=lambda p: p.best_time_seconds)
            return score_qualified[:time_qualified_count]
        
        # Default: tutti qualificati
        return participants

    async def setup_next_phase_or_complete_tournament(self, tournament: Tournament):
        """Avvia la fase successiva o completa il torneo se è l'ultima"""
        
        if tournament.current_phase >= tournament.total_phases:
            # Torneo completato
            await self._complete_tournament(tournament)
        else:
            # Avvia fase successiva
            await self._start_next_phase(tournament)

    async def _start_next_phase(self, tournament: Tournament):
        """Avvia la fase successiva del torneo"""
        
        tournament.current_phase += 1
        
        # Trova la fase da attivare
        stmt = select(TournamentPhase).where(
            and_(
                TournamentPhase.tournament_id == tournament.id,
                TournamentPhase.phase_number == tournament.current_phase
            )
        )
        result = await self.db.execute(stmt)
        next_phase = result.scalar_one_or_none()
        
        if not next_phase:
            raise ValueError(f"Phase {tournament.current_phase} not found for tournament {tournament.id}")
        
        # Attiva la fase
        next_phase.start_phase()
        
        # Copia partecipanti qualificati dalla fase precedente
        if tournament.current_phase > 1:
            await self._copy_qualified_participants_to_next_phase(tournament, next_phase)
        else:
            # Prima fase: copia tutti i partecipanti del pool
            await self._create_initial_participants(tournament, next_phase)
        
        await self.db.commit()

    async def _complete_tournament(self, tournament: Tournament):
        """Completa il torneo e determina i vincitori"""
        
        tournament.status = TournamentStatus.COMPLETED
        tournament.completed_at = datetime.utcnow()
        
        # Aggiorna stato del pool originale
        pool = await self.db.get(RafflePool, tournament.pool_id)
        if pool:
            pool.state = "TOURNAMENT_COMPLETED"
        
        # TODO: Logica assegnazione premi basata sulla classifica finale
        await self._assign_tournament_rewards(tournament)
        
        await self.db.commit()

    async def _copy_qualified_participants_to_next_phase(
        self, 
        tournament: Tournament, 
        next_phase: TournamentPhase
    ):
        """Copia i partecipanti qualificati alla fase successiva"""
        
        # Trova partecipanti qualificati della fase precedente
        stmt = select(TournamentParticipant).where(
            and_(
                TournamentParticipant.tournament_id == tournament.id,
                TournamentParticipant.qualified == True
            )
        ).order_by(desc(TournamentParticipant.phase_id))
        
        result = await self.db.execute(stmt)
        qualified_participants = result.scalars().all()
        
        # Crea nuovi record per la fase successiva
        for participant in qualified_participants:
            new_participant = TournamentParticipant(
                tournament_id=tournament.id,
                phase_id=next_phase.id,
                player_id=participant.player_id,
                qualified=False,  # Reset per nuova fase
                best_score=0,
                best_time_seconds=None,
                sessions_count=0
            )
            self.db.add(new_participant)
        
        next_phase.participants_count = len(qualified_participants)

    async def _create_initial_participants(
        self, 
        tournament: Tournament, 
        first_phase: TournamentPhase
    ):
        """Crea i partecipanti iniziali dalla lista ticket del pool"""
        
        # TODO: Query per ottenere tutti i giocatori che hanno comprato ticket nel pool
        # Per ora placeholder - implementare quando si ha la struttura ticket/players
        
        first_phase.participants_count = 0  # Da aggiornare con query reale

    async def _assign_tournament_rewards(self, tournament: Tournament):
        """Assegna i premi finali basati sulla classifica"""
        
        # TODO: Implementare logica premi
        # - Vincitore: premio principale del pool
        # - 2°/3° posto: premi secondari o ticket bonus
        # - Partecipazione: coins/XP
        pass

    async def start_tournament_manually(self, tournament_id: str) -> Tournament:
        """Avvia manualmente un torneo (override della schedulazione)"""
        
        tournament = await self.db.get(Tournament, tournament_id)
        if not tournament:
            raise HTTPException(status_code=404, detail="Tournament not found")
        
        if tournament.status != TournamentStatus.READY:
            raise HTTPException(
                status_code=400,
                detail=f"Tournament must be in READY status, current: {tournament.status}"
            )
        
        tournament.status = TournamentStatus.ACTIVE
        tournament.current_phase = 1
        
        # Avvia prima fase
        await self._start_next_phase(tournament)
        
        return tournament