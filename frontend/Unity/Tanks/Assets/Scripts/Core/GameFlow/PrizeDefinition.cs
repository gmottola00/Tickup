using System.Collections.Generic;
using UnityEngine;

namespace Tickup.Core.GameFlow
{
    [CreateAssetMenu(menuName = "Tickup/Prizes/Definition")]
    public sealed class PrizeDefinition : ScriptableObject
    {
        [System.Serializable]
        public struct Step
        {
            public MinigameDefinition Minigame;
            [Range(1, 5)] public int RequiredWins;
        }

        [SerializeField] private string prizeId;
        [SerializeField] private List<Step> steps = new();

        public string PrizeId => prizeId;
        public IReadOnlyList<Step> Steps => steps;
    }
}
