using System;
using Tickup.Core.GameFlow;
using Tanks.Complete;
using UnityEngine;

namespace Tickup.Minigames.Tanks
{
    public sealed class TanksMinigameController : MonoBehaviour, IMinigameController
    {
        [SerializeField] private GameManager gameManager;

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
