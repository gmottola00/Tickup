using UnityEngine;

namespace Tickup.Core.GameFlow
{
    [CreateAssetMenu(menuName = "Tickup/Minigames/Definition")]
    public sealed class MinigameDefinition : ScriptableObject
    {
        [SerializeField] private string minigameId;
        [SerializeField] private string sceneName;
        [SerializeField] private string scenePath;
        [SerializeField] private string displayName;
        [TextArea]
        [SerializeField] private string description;
        [SerializeField] private Sprite previewImage;

        public string MinigameId => minigameId;
        public string SceneName => sceneName;
        public string ScenePath => scenePath;
        public string SceneIdentifier => string.IsNullOrWhiteSpace(sceneName) ? scenePath : sceneName;
        public string DisplayName => displayName;
        public string Description => description;
        public Sprite PreviewImage => previewImage;

#if UNITY_EDITOR
        private void OnValidate()
        {
            if (string.IsNullOrEmpty(sceneName) && !string.IsNullOrEmpty(scenePath))
            {
                var unitySceneName = System.IO.Path.GetFileNameWithoutExtension(scenePath);
                if (!string.IsNullOrEmpty(unitySceneName))
                    sceneName = unitySceneName;
            }

            if (string.IsNullOrEmpty(scenePath) && !string.IsNullOrEmpty(sceneName))
            {
                var matches = UnityEditor.AssetDatabase.FindAssets($"{sceneName} t:Scene");
                if (matches != null && matches.Length > 0)
                {
                    var path = UnityEditor.AssetDatabase.GUIDToAssetPath(matches[0]);
                    if (!string.IsNullOrEmpty(path))
                        scenePath = path;
                }
            }
        }
#endif
    }
}
