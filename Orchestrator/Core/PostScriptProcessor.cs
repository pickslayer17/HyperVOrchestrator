namespace Orchestrator.Core;

internal sealed class PostScriptProcessor
{
    private readonly ResultParser _resultParser;

    public PostScriptProcessor(ResultParser resultParser)
    {
        _resultParser = resultParser;
    }

    public Action<string> WrapLineHandler(Action<string> onLine)
    {
        void Handler(string line)
        {
            _resultParser.CaptureSets(line);
            onLine(line);
        }
        return Handler;
    }
}
