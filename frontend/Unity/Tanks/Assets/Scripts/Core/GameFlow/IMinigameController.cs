using System;

namespace Tickup.Core.GameFlow
{
    public interface IMinigameController
    {
        event Action<MinigameResult> Completed;
        void Initialize(MinigameDefinition definition);
        void Begin();
        void Terminate();
    }
}
