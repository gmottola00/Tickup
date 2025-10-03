using System.Collections.Generic;
using UnityEngine;

namespace Tickup.Core.GameFlow
{
    [CreateAssetMenu(menuName = "Tickup/Minigames/Registry")]
    public sealed class MinigameRegistry : ScriptableObject
    {
        [SerializeField] private List<MinigameDefinition> definitions = new();

        private readonly Dictionary<string, MinigameDefinition> lookup = new();

        private void OnEnable()
        {
            lookup.Clear();

            foreach (var definition in definitions)
            {
                if (definition == null)
                    continue;

                var id = definition.MinigameId;
                if (string.IsNullOrWhiteSpace(id))
                    continue;

                lookup[id] = definition;
            }
        }

        public bool TryGetById(string id, out MinigameDefinition definition)
            => lookup.TryGetValue(id, out definition);

        public IReadOnlyList<MinigameDefinition> Definitions => definitions;
    }
}
