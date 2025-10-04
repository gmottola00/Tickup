using System;
using UnityEngine;
using Tickup.Core.GameFlow;
using UnityEngine.SceneManagement;

#if TICKUP_USE_FLUTTER_WIDGET
using FlutterUnityIntegration;
#endif

namespace Tickup.Core.Messaging
{
    public sealed class FlutterBridge : MonoBehaviour
    {
        [SerializeField] private PrizeRunManager prizeRunManager;

#if UNITY_ANDROID && !UNITY_EDITOR
        private const string AndroidBridgeClass = "com.example.skillwin_frontend.UnityBridge";
#endif

        private void Awake()
        {
            DontDestroyOnLoad(gameObject);

            SceneManager.sceneLoaded += HandleSceneLoaded;
            NotifyScene(SceneManager.GetActiveScene().name);

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
            SceneManager.sceneLoaded -= HandleSceneLoaded;

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

        private void HandleSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            NotifyScene(scene.name);
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
            DispatchToNative(type, payload);
            Debug.Log($"FlutterBridge -> {type}: {payload}");
        }

        private static void NotifyScene(string sceneName)
        {
#if TICKUP_USE_FLUTTER_WIDGET
            SendToFlutter("sceneLoaded", sceneName);
#else
            DispatchScene(sceneName);
#endif
        }

#if UNITY_ANDROID && !UNITY_EDITOR
        private static void DispatchScene(string sceneName)
        {
            try
            {
                using var bridge = new AndroidJavaClass(AndroidBridgeClass);
                bridge?.CallStatic("notifySceneLoaded", sceneName);
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"Failed to dispatch scene '{sceneName}' to Android: {ex.Message}");
            }
        }

        private static void DispatchToNative(string type, string payload)
        {
            try
            {
                using var bridge = new AndroidJavaClass(AndroidBridgeClass);
                bridge?.CallStatic("notifyGameEvent", type, payload);
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"Failed to dispatch '{type}' event to Android: {ex.Message}");
            }
        }
#else
        private static void DispatchScene(string sceneName) { }
        private static void DispatchToNative(string type, string payload) { }
#endif

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
