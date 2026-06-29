namespace Orchestrator.Models;

internal sealed class Result
{
    public int ExitCode { get; set; }
    public string Output { get; set; } = "";
}
