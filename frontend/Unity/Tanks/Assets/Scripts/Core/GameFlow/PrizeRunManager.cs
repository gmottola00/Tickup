using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Tickup.Core.GameFlow
{
    public sealed class PrizeRunManager : MonoBehaviour
    {
        [SerializeField] private PrizeDefinition defaultPrize;
        [SerializeField] private MinigameRegistry registry;
        [SerializeField] private List<PrizeDefinition> availablePrizes = new();

        private readonly SceneLoader sceneLoader = new();
        private readonly Queue<StepRunState> stepQueue = new();

        private StepRunState activeStep;
        private IMinigameController activeController;
        private Action<MinigameResult> controllerCallback;
        private PrizeDefinition activePrize;

        public event Action<string> PrizeStarted;
        public event Action<string> PrizeCompleted;
        public event Action PrizeAborted;
        public event Action<MinigameResult> MinigameCompleted;

        private void Start()
        {
            if (defaultPrize != null)
                StartPrizeRun(defaultPrize);
        }

        public void StartPrizeRun(PrizeDefinition prize)
        {
            if (prize == null)
                throw new ArgumentNullException(nameof(prize));

            activePrize = prize;
            stepQueue.Clear();
            activeStep = null;

            foreach (var step in prize.Steps)
            {
                var resolved = ResolveDefinition(step.Minigame);
                var requiredWins = Mathf.Max(1, step.RequiredWins);
                stepQueue.Enqueue(new StepRunState(step, resolved, requiredWins));
            }

            PrizeStarted?.Invoke(prize.PrizeId);
            _ = AdvanceToNextStepAsync();
        }

        public Task StartPrizeRunByIdAsync(string prizeId)
        {
            if (string.IsNullOrWhiteSpace(prizeId))
                throw new ArgumentException("Prize id is missing", nameof(prizeId));

            var prize = FindPrizeDefinition(prizeId);
            if (prize == null)
                throw new InvalidOperationException($"Prize '{prizeId}' not configured.");

            StartPrizeRun(prize);
            return Task.CompletedTask;
        }

        public async Task AbortActivePrizeAsync()
        {
            stepQueue.Clear();
            activePrize = null;
            activeStep = null;

            if (activeController != null)
            {
                activeController.Completed -= controllerCallback;
                activeController.Terminate();
                activeController = null;
                controllerCallback = null;
            }

            await sceneLoader.UnloadCurrentAsync();
            PrizeAborted?.Invoke();
        }

        private PrizeDefinition FindPrizeDefinition(string prizeId)
        {
            foreach (var prize in availablePrizes)
            {
                if (prize != null && string.Equals(prize.PrizeId, prizeId, StringComparison.Ordinal))
                    return prize;
            }

            return null;
        }

        private async Task AdvanceToNextStepAsync()
        {
            await sceneLoader.UnloadCurrentAsync();

            if (stepQueue.Count == 0)
            {
                var completedPrizeId = activePrize?.PrizeId;
                activePrize = null;
                if (!string.IsNullOrEmpty(completedPrizeId))
                    PrizeCompleted?.Invoke(completedPrizeId);
                return;
            }

            activeStep = stepQueue.Dequeue();

            var sceneIdentifier = activeStep.Definition.SceneIdentifier;
            if (string.IsNullOrWhiteSpace(sceneIdentifier))
                throw new InvalidOperationException($"Minigame '{activeStep.Definition.MinigameId}' is missing its scene name.");

            var scene = await sceneLoader.LoadSceneAsync(sceneIdentifier);
            activeController = FindController(scene);

            if (activeController == null)
                throw new InvalidOperationException($"Scene '{scene.name}' is missing a component that implements {nameof(IMinigameController)}.");

            controllerCallback = HandleResult;
            activeController.Completed += controllerCallback;
            activeController.Initialize(activeStep.Definition);
            activeController.Begin();
        }

        private MinigameDefinition ResolveDefinition(MinigameDefinition definition)
        {
            if (definition != null)
                return definition;

            if (registry == null)
                throw new InvalidOperationException("Minigame registry not configured.");

            throw new InvalidOperationException("Step references an empty minigame definition.");
        }

        private async void HandleResult(MinigameResult result)
        {
            if (activeController != null)
            {
                activeController.Completed -= controllerCallback;
                activeController.Terminate();
                activeController = null;
                controllerCallback = null;
            }

            MinigameCompleted?.Invoke(result);

            if (activeStep != null)
            {
                if (result.Success)
                {
                    activeStep.PendingWins--;
                    if (activeStep.PendingWins > 0)
                        stepQueue.Enqueue(activeStep);
                }
                else
                {
                    stepQueue.Enqueue(activeStep);
                }
            }

            activeStep = null;
            await AdvanceToNextStepAsync();
        }

        private static IMinigameController FindController(Scene scene)
        {
            var roots = scene.GetRootGameObjects();
            for (int i = 0; i < roots.Length; i++)
            {
                var controller = roots[i].GetComponentInChildren<IMinigameController>(true);
                if (controller != null)
                    return controller;
            }

            return null;
        }

        private sealed class StepRunState
        {
            public StepRunState(PrizeDefinition.Step step, MinigameDefinition definition, int pendingWins)
            {
                Step = step;
                Definition = definition;
                PendingWins = pendingWins;
            }

            public PrizeDefinition.Step Step { get; }
            public MinigameDefinition Definition { get; }
            public int PendingWins { get; set; }
        }
    }
}
