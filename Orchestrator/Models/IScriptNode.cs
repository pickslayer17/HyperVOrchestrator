namespace Orchestrator.Models;

internal interface IScriptNode
{
    string Name { get; }
    Suite? Parent { get; set; }
}
