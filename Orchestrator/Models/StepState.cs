namespace Orchestrator.Models;

internal enum StepState
{
    NotRun,
    Failed,
    Passed,
    AlreadyDone,
    NoCheck,
}
