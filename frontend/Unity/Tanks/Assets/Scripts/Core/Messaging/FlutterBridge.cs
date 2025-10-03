using System;
using UnityEngine;
using Tickup.Core.GameFlow;

#if TICKUP_USE_FLUTTER_WIDGET
using FlutterUnityIntegration;
#endif

namespace Tickup.Core.Messaging
{
    public sealed class FlutterBridge : MonoBehaviour
    {
        [SerializeField] private PrizeRunManager prizeRunManager;

        private void Awake()
        {
            DontDestroyOnLoad(gameObject);

            if (prizeRunManager == null)
                prizeRunManager = FindObjectOfType<PrizeRunManager>();

            if (prizeRunManager != null)
            {
                prizeRunManager.PrizeCompleted += HandlePrizeCompleted;
                prizeRunManager.MinigameCompleted += HandleMinigameCompleted;
                prizeRunManager.PrizeAborted += HandlePrizeAborted;
            }

#if TICKUP_USE_FLUTTER_WIDGET
            if (TryGetMessageManager(out var manager))
                manager.OnMessage += OnFlutterMessage;
#else
            Debug.Log("FlutterBridge active without flutter_unity_widget. Messages will log locally. Define TICKUP_USE_FLUTTER_WIDGET once the plugin is installed to enable native messaging.");
#endif
        }

        private void OnDestroy()
        {
            if (prizeRunManager != null)
            {
                prizeRunManager.PrizeCompleted -= HandlePrizeCompleted;
                prizeRunManager.MinigameCompleted -= HandleMinigameCompleted;
                prizeRunManager.PrizeAborted -= HandlePrizeAborted;
            }

#if TICKUP_USE_FLUTTER_WIDGET
            if (TryGetMessageManager(out var manager))
                manager.OnMessage -= OnFlutterMessage;
#endif
        }

        private void OnFlutterMessage(string message)
        {
            if (string.IsNullOrEmpty(message))
                return;

            var envelope = JsonUtility.FromJson<FlutterCommand>(message);
            switch (envelope.type)
            {
                case "startPrize":
                    HandleStartPrize(envelope.payload);
                    break;
                case "abortPrize":
                    HandleAbortPrize();
                    break;
            }
        }

        private async void HandleStartPrize(string prizeId)
        {
            if (prizeRunManager == null)
                return;

            try
            {
                await prizeRunManager.StartPrizeRunByIdAsync(prizeId);
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to start prize '{prizeId}': {ex.Message}");
            }
        }

        private async void HandleAbortPrize()
        {
            if (prizeRunManager == null)
                return;

            await prizeRunManager.AbortActivePrizeAsync();
        }

        private void HandlePrizeCompleted(string prizeId)
        {
            SendToFlutter("prizeComplete", prizeId);
        }

        private void HandlePrizeAborted()
        {
            SendToFlutter("prizeAborted", string.Empty);
        }

        private void HandleMinigameCompleted(MinigameResult result)
        {
            var payload = JsonUtility.ToJson(result);
            SendToFlutter("minigameComplete", payload);
        }

        private static void SendToFlutter(string type, string payload)
        {
#if TICKUP_USE_FLUTTER_WIDGET
            if (TryGetMessageManager(out var manager))
            {
                var message = JsonUtility.ToJson(new FlutterCommand { type = type, payload = payload });
                manager.SendMessageToFlutter(message);
                return;
            }
#endif
            Debug.Log($"FlutterBridge -> {type}: {payload}");
        }

        [Serializable]
        private struct FlutterCommand
        {
            public string type;
            public string payload;
        }

#if TICKUP_USE_FLUTTER_WIDGET
        private static bool TryGetMessageManager(out UnityMessageManager manager)
        {
            manager = null;

            if (!UnityMessageManager.HasInstance)
                return false;

            manager = UnityMessageManager.Instance;
            return manager != null;
        }
#endif
    }
}
