using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class ConsoleModelViewer
{
    private const string Footer = "  [up/down] move   [Enter] run   [Esc] back   [q] quit";
    private const string MenuFooter = "  [up/down] move   [Enter] select   [q] quit";

    private readonly Orchestrator _orchestrator;
    private ScriptModel _model = new ScriptModel { Root = new Suite() };
    private readonly List<IScriptNode> _flatNodes = new List<IScriptNode>();
    private readonly List<string> _headerLines = new List<string>();
    private int _cursorIndex;
    private int _bodyRow;

    public ConsoleModelViewer(Orchestrator orchestrator)
    {
        _orchestrator = orchestrator;
    }

    public int ShowMenu(IReadOnlyList<string> items)
    {
        var cursor = 0;
        while (true)
        {
            DrawMenu(items, cursor);
            var key = Console.ReadKey(intercept: true);
            if (key.Key == ConsoleKey.UpArrow && cursor > 0)
                cursor--;
            else if (key.Key == ConsoleKey.DownArrow && cursor < items.Count - 1)
                cursor++;
            else if (key.Key == ConsoleKey.Enter)
                return cursor;
            else if (key.Key == ConsoleKey.Escape)
                return items.Count - 1;
            else if (key.Key == ConsoleKey.Q)
            {
                Console.CursorVisible = true;
                Environment.Exit(0);
            }
        }
    }

    private void DrawMenu(IReadOnlyList<string> items, int cursor)
    {
        HideCursor();
        Console.Clear();
        RenderHeader();
        Console.SetCursorPosition(0, HeaderHeight);
        for (var index = 0; index < items.Count; index++)
        {
            var marker = index == cursor ? ">" : " ";
            Console.ForegroundColor = index == cursor ? ConsoleColor.White : ConsoleColor.Gray;
            Console.WriteLine($"  {marker} {items[index]}");
            Console.ResetColor();
        }
        Console.WriteLine();
        Console.WriteLine(MenuFooter);
    }

    public void ShowTree(ScriptModel model)
    {
        _model = model;
        _cursorIndex = 0;
        while (true)
        {
            Draw();
            var key = Console.ReadKey(intercept: true);
            if (key.Key == ConsoleKey.UpArrow)
                MoveCursor(-1);
            else if (key.Key == ConsoleKey.DownArrow)
                MoveCursor(1);
            else if (key.Key == ConsoleKey.Enter)
            {
                var node = _flatNodes[_cursorIndex];
                BeginRun();
                _orchestrator.Run(node);
            }
            else if (key.Key == ConsoleKey.Escape)
                return;
            else if (key.Key == ConsoleKey.Q)
            {
                Console.CursorVisible = true;
                Environment.Exit(0);
            }
        }
    }

    public void SetHeader(IReadOnlyList<string> lines)
    {
        _headerLines.Clear();
        _headerLines.AddRange(lines);
    }

    private int HeaderHeight => _headerLines.Count == 0 ? 0 : _headerLines.Count + 1;

    private void Draw()
    {
        RebuildFlatNodes();
        HideCursor();
        Console.Clear();
        RenderHeader();

        Console.SetCursorPosition(0, HeaderHeight);
        for (var index = 0; index < _flatNodes.Count; index++)
            DrawNode(_flatNodes[index], index);

        Console.WriteLine();
        Console.WriteLine(Footer);
    }

    public void WriteOutput(string line)
    {
        try
        {
            var width = SafeWidth();
            var lastRow = Console.WindowHeight - 1;
            if (_bodyRow > lastRow)
            {
                var bodyHeight = lastRow - HeaderHeight;
                if (bodyHeight > 0)
                    Console.MoveBufferArea(0, HeaderHeight + 1, Console.BufferWidth, bodyHeight, 0, HeaderHeight);
                _bodyRow = lastRow;
            }
            WriteRow(_bodyRow, line, width);
            _bodyRow++;
        }
        catch
        {
            Console.WriteLine(line);
        }
    }

    public bool ConfirmInHeader(string question)
    {
        var previous = new List<string>(_headerLines);
        SetHeader(new[] { question });
        HideCursor();
        Console.Clear();
        RenderHeader();
        var confirmed = ReadConfirmation();
        SetHeader(previous);
        Console.Clear();
        RenderHeader();
        _bodyRow = HeaderHeight;
        return confirmed;
    }

    private static bool ReadConfirmation()
    {
        try
        {
            while (Console.KeyAvailable)
                Console.ReadKey(intercept: true);
            return Console.ReadKey(intercept: true).Key == ConsoleKey.Y;
        }
        catch
        {
            return false;
        }
    }

    public void ResumeAfterRun()
    {
        WriteOutput("");
        WriteOutput("  -- done, press any key --");
        Console.ReadKey(intercept: true);
    }

    public void BeginRun()
    {
        HideCursor();
        Console.Clear();
        RenderHeader();
        _bodyRow = HeaderHeight;
    }

    private void RenderHeader()
    {
        if (HeaderHeight == 0)
            return;

        var width = SafeWidth();
        Console.ForegroundColor = ConsoleColor.Cyan;
        for (var index = 0; index < _headerLines.Count; index++)
            WriteRow(index, _headerLines[index], width);
        Console.ResetColor();
        WriteRow(_headerLines.Count, new string('=', Math.Max(0, width - 1)), width);
    }

    private static void WriteRow(int row, string text, int width)
    {
        var max = Math.Max(0, width - 1);
        var content = text.Length > max ? text.Substring(0, max) : text.PadRight(max);
        Console.SetCursorPosition(0, row);
        Console.Write(content);
    }

    private void MoveCursor(int delta)
    {
        var next = _cursorIndex + delta;
        if (next < 0)
            next = 0;
        if (next > _flatNodes.Count - 1)
            next = _flatNodes.Count - 1;
        _cursorIndex = next;
    }

    private void DrawNode(IScriptNode node, int index)
    {
        var isCursor = index == _cursorIndex;
        var state = StateOf(node);
        Console.ForegroundColor = ColorFor(state, isCursor);
        Console.WriteLine(BuildNodeText(node, index));
        Console.ResetColor();
    }

    private string BuildNodeText(IScriptNode node, int index)
    {
        var depth = Depth(node);
        var indent = new string(' ', 2 + depth * 2);
        var marker = index == _cursorIndex ? ">" : " ";
        var state = StateOf(node);
        return $"{indent}{marker} {Glyph(state)} {node.Name}{Suffix(state)}";
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

    public void FixWindowSize(int contentLines)
    {
        try
        {
            var wanted = Math.Min(contentLines + 8, Console.LargestWindowHeight);
            if (wanted < 1)
                return;

            if (wanted < Console.WindowHeight)
            {
                Console.SetWindowSize(Console.WindowWidth, wanted);
                Console.SetBufferSize(Console.BufferWidth, wanted);
            }
            else if (wanted > Console.WindowHeight)
            {
                Console.SetBufferSize(Console.BufferWidth, Math.Max(wanted, Console.BufferHeight));
                Console.SetWindowSize(Console.WindowWidth, wanted);
            }
        }
        catch
        {
        }
    }

    private int DesiredHeight()
    {
        return HeaderHeight + _flatNodes.Count + 3;
    }

    private static int SafeWidth()
    {
        try { return Console.WindowWidth; }
        catch { return 80; }
    }

    private static void HideCursor()
    {
        try { Console.CursorVisible = false; }
        catch { }
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
