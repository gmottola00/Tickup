using System;
using System.Threading.Tasks;
using UnityEngine.SceneManagement;

namespace Tickup.Core.GameFlow
{
    public sealed class SceneLoader
    {
        private string currentSceneIdentifier;

        public async Task<Scene> LoadSceneAsync(string identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier))
                throw new ArgumentException("Scene identifier is missing", nameof(identifier));

            await UnloadCurrentAsync();

            var operation = SceneManager.LoadSceneAsync(identifier, LoadSceneMode.Additive);
            if (operation == null)
                throw new InvalidOperationException($"Unable to load scene '{identifier}'. Ensure it is added to Build Settings.");

            var tcs = new TaskCompletionSource<bool>();
            operation.completed += _ => tcs.TrySetResult(true);
            await tcs.Task;

            currentSceneIdentifier = identifier;
            var scene = GetScene(identifier);
            if (scene.IsValid())
                SceneManager.SetActiveScene(scene);

            return scene;
        }

        public async Task UnloadCurrentAsync()
        {
            if (string.IsNullOrEmpty(currentSceneIdentifier))
                return;

            var scene = GetScene(currentSceneIdentifier);
            currentSceneIdentifier = null;

            if (!scene.IsValid())
                return;

            var operation = SceneManager.UnloadSceneAsync(scene);
            if (operation == null)
                return;

            var tcs = new TaskCompletionSource<bool>();
            operation.completed += _ => tcs.TrySetResult(true);
            await tcs.Task;
        }

        private static Scene GetScene(string identifier)
        {
            if (string.IsNullOrEmpty(identifier))
                return default;

            if (identifier.EndsWith(".unity", StringComparison.OrdinalIgnoreCase) || identifier.Contains("/"))
                return SceneManager.GetSceneByPath(identifier);

            return SceneManager.GetSceneByName(identifier);
        }
    }
}
