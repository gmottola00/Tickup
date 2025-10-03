using System;
using Tickup.Core.GameFlow;
using Tanks.Complete;
using UnityEngine;

namespace Tickup.Minigames.Tanks
{
    public sealed class TanksMinigameController : MonoBehaviour, IMinigameController
    {
        [SerializeField] private GameManager gameManager;
        [SerializeField] private Color humanPlayerColor = new(0.82f, 0.19f, 0.16f);
        [SerializeField] private Color aiPlayerColor = new(0.15f, 0.39f, 0.75f);
        [SerializeField] private GameObject humanTankPrefabOverride;
        [SerializeField] private GameObject aiTankPrefabOverride;

        private MinigameDefinition definition;
        private bool isRunning;
        private float runStartTime;
        private bool originalAutoRestart;

        public event Action<MinigameResult> Completed;

        public void Initialize(MinigameDefinition minigameDefinition)
        {
            definition = minigameDefinition;

            if (gameManager == null)
                gameManager = FindAnyObjectByType<GameManager>(FindObjectsInactive.Include);

            if (gameManager == null)
                throw new InvalidOperationException("TanksMinigameController requires a GameManager in the scene.");

            originalAutoRestart = gameManager.AutoRestartScene;
            gameManager.AutoRestartScene = false;
            gameManager.GameEnded += OnGameEnded;
        }

        public void Begin()
        {
            if (gameManager == null)
                return;

            isRunning = true;
            runStartTime = Time.time;

            gameManager.m_NumRoundsToWin = 1;
            gameManager.StartGame(CreateDefaultPlayers());
        }

        public void Terminate()
        {
            if (gameManager != null)
            {
                gameManager.GameEnded -= OnGameEnded;
                gameManager.AutoRestartScene = originalAutoRestart;
            }

            isRunning = false;
        }

        private void OnDestroy()
        {
            Terminate();
        }

        private GameManager.PlayerData[] CreateDefaultPlayers()
        {
            var human = new GameManager.PlayerData
            {
                IsComputer = false,
                TankColor = humanPlayerColor,
                UsedPrefab = humanTankPrefabOverride != null ? humanTankPrefabOverride : gameManager.m_Tank1Prefab,
                ControlIndex = 1
            };

            var ai = new GameManager.PlayerData
            {
                IsComputer = true,
                TankColor = aiPlayerColor,
                UsedPrefab = aiTankPrefabOverride != null ? aiTankPrefabOverride : gameManager.m_Tank2Prefab,
                ControlIndex = -1
            };

            return new[] { human, ai };
        }

        private void OnGameEnded(TankManager winner)
        {
            if (!isRunning)
                return;

            isRunning = false;

            var success = winner != null && !winner.m_ComputerControlled;
            var result = new MinigameResult
            {
                MinigameId = definition != null ? definition.MinigameId : "tanks",
                Success = success,
                Score = winner != null ? winner.m_Wins : 0,
                Duration = Time.time - runStartTime
            };

            Completed?.Invoke(result);
        }
    }
}
