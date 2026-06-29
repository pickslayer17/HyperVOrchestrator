namespace Orchestrator.Core;

internal sealed class Logger
{
    private readonly string _logPath;
    private string _context = "";

    public Logger(string repoRoot)
    {
        var logsDir = Path.Combine(repoRoot, "artifacts", "logs");
        Directory.CreateDirectory(logsDir);
        var fileName = $"run-{DateTime.Now:yyyy-MM-dd-HHmmss}.log";
        _logPath = Path.Combine(logsDir, fileName);
    }

    public void SetContext(string suiteStepPhase)
    {
        _context = suiteStepPhase;
    }

    public void Write(string line)
    {
        var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        var entry = $"[{timestamp}][{_context}] {line}";
        File.AppendAllText(_logPath, entry + Environment.NewLine);
    }
}
