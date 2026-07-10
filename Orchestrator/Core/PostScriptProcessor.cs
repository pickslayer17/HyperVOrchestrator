namespace Orchestrator.Core;

internal sealed class PostScriptProcessor
{
    public Action<string> WrapLineHandler(Action<string> onLine)
    {
        return onLine;
    }
}
