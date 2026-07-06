using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class ConsoleModelViewer
{
    private readonly Orchestrator _orchestrator;
    private readonly ScriptModel _model;
    private readonly List<IScriptNode> _flatNodes = new List<IScriptNode>();
    private int _cursorIndex;

    public ConsoleModelViewer(Orchestrator orchestrator, ScriptModel model)
    {
        _orchestrator = orchestrator;
        _model = model;
    }

    public void Draw()
    {
        RebuildFlatNodes();
        Console.Clear();
        Console.WriteLine("  TestRunner orchestrator");
        Console.WriteLine("  =======================");
        Console.WriteLine();

        for (var index = 0; index < _flatNodes.Count; index++)
            DrawNode(_flatNodes[index], index);

        Console.WriteLine();
        Console.WriteLine("  [up/down] move   [Enter] run   [q] quit");
        ReadKeys();
    }

    public void WriteOutput(string line)
    {
        Console.WriteLine(line);
    }

    public void ResumeAfterRun()
    {
        Console.WriteLine();
        Console.WriteLine("  -- done, press any key --");
        Console.ReadKey(intercept: true);
        Draw();
    }

    private void ReadKeys()
    {
        while (true)
        {
            var key = Console.ReadKey(intercept: true);
            if (key.Key == ConsoleKey.UpArrow)
            {
                MoveCursor(-1);
                return;
            }
            if (key.Key == ConsoleKey.DownArrow)
            {
                MoveCursor(1);
                return;
            }
            if (key.Key == ConsoleKey.Enter)
            {
                Console.WriteLine("Starting...");
                var node = _flatNodes[_cursorIndex];
                _orchestrator.Run(node);
                return;
            }
            if (key.Key == ConsoleKey.Q)
            {
                Environment.Exit(0);
            }
        }
    }

    private void MoveCursor(int delta)
    {
        var next = _cursorIndex + delta;
        if (next < 0)
            next = 0;
        if (next > _flatNodes.Count - 1)
            next = _flatNodes.Count - 1;
        _cursorIndex = next;
        Draw();
    }

    private void DrawNode(IScriptNode node, int index)
    {
        var depth = Depth(node);
        var indent = new string(' ', 2 + depth * 2);
        var isCursor = index == _cursorIndex;
        var marker = isCursor ? ">" : " ";

        var state = StateOf(node);
        Console.ForegroundColor = ColorFor(state, isCursor);
        Console.WriteLine($"{indent}{marker} {Glyph(state)} {node.Name}{Suffix(state)}");
        Console.ResetColor();
    }

    private void RebuildFlatNodes()
    {
        _flatNodes.Clear();
        AppendNode(_model.Root);
    }

    private void AppendNode(Suite suite)
    {
        _flatNodes.Add(suite);
        foreach (var step in suite.Steps)
            _flatNodes.Add(step);
        foreach (var childSuite in suite.ChildSuites)
            AppendNode(childSuite);
    }

    private int Depth(IScriptNode node)
    {
        var depth = 0;
        var parent = node.Parent;
        while (parent is not null)
        {
            depth = depth + 1;
            parent = parent.Parent;
        }
        return depth;
    }

    private StepState StateOf(IScriptNode node)
    {
        if (node is Step step)
            return step.State;
        var suite = (Suite)node;
        return suite.State;
    }

    private ConsoleColor ColorFor(StepState state, bool isCursor)
    {
        if (isCursor)
            return ConsoleColor.White;
        if (state == StepState.Passed)
            return ConsoleColor.Green;
        if (state == StepState.NoCheck)
            return ConsoleColor.Green;
        if (state == StepState.AlreadyDone)
            return ConsoleColor.Yellow;
        if (state == StepState.Failed)
            return ConsoleColor.Red;
        return ConsoleColor.Blue;
    }

    private string Glyph(StepState state)
    {
        if (state == StepState.Passed)
            return "[v]";
        if (state == StepState.NoCheck)
            return "[v]";
        if (state == StepState.AlreadyDone)
            return "[v]";
        if (state == StepState.Failed)
            return "[x]";
        return "[ ]";
    }

    private string Suffix(StepState state)
    {
        if (state == StepState.NoCheck)
            return "  (no check)";
        return "";
    }
}
