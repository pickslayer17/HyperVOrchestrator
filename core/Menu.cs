namespace Orchestrator;

// Один пункт стрелочного меню.
internal sealed class MenuItem
{
    public enum Kind { RunAll, Suite, Step }

    public required Kind ItemKind { get; init; }
    public required string Label { get; init; }
    public string? Group { get; init; }    // для Suite/Step
    public ScriptStep? Step { get; init; }  // только для Step
}

// Стрелочное меню: Up/Down двигают подсветку, Enter запускает, q/Esc — выход.
// Свой рендер через Console (нужен контроль подсветки/цветов). Структура:
//   RUN ALL suites      -> все сьюты подряд
//   [суьют]             -> все шаги сьюта с первого
//       шаг             -> только этот шаг
// Прогон последовательности (сьют / RUN ALL) НЕ спрашивает Enter между шагами;
// первый упавший шаг останавливает сьют (и весь RUN ALL). Само выполнение шага —
// делегат runStep (возвращает успех).
internal sealed class Menu
{
    private readonly IReadOnlyList<(string Group, IReadOnlyList<ScriptStep> Steps)> _suites;
    private readonly SessionStatus _status;
    private readonly Func<ScriptStep, bool> _runStep;
    private readonly List<MenuItem> _items;
    private int _cursor;

    public Menu(
        IReadOnlyList<(string Group, IReadOnlyList<ScriptStep> Steps)> suites,
        SessionStatus status,
        Func<ScriptStep, bool> runStep)
    {
        _suites = suites;
        _status = status;
        _runStep = runStep;
        _items = Build();
    }

    private List<MenuItem> Build()
    {
        var items = new List<MenuItem>
        {
            new() { ItemKind = MenuItem.Kind.RunAll, Label = "RUN ALL suites" },
        };
        foreach (var (group, steps) in _suites)
        {
            items.Add(new() { ItemKind = MenuItem.Kind.Suite, Label = group == "" ? "(root)" : group, Group = group });
            foreach (var step in steps)
                items.Add(new() { ItemKind = MenuItem.Kind.Step, Label = step.Name, Group = group, Step = step });
        }
        return items;
    }

    public void Run()
    {
        if (_items.Count == 0)
            return;

        while (true)
        {
            Draw();
            switch (Console.ReadKey(intercept: true).Key)
            {
                case ConsoleKey.UpArrow:
                    _cursor = (_cursor - 1 + _items.Count) % _items.Count;
                    break;
                case ConsoleKey.DownArrow:
                    _cursor = (_cursor + 1) % _items.Count;
                    break;
                case ConsoleKey.Enter:
                    Activate(_items[_cursor]);
                    Ui.Blank();
                    Ui.Prompt("Press Enter to return to menu...");
                    break;
                case ConsoleKey.Q:
                case ConsoleKey.Escape:
                    return;
            }
        }
    }

    private void Activate(MenuItem item)
    {
        switch (item.ItemKind)
        {
            case MenuItem.Kind.Step:
                _runStep(item.Step!);
                break;
            case MenuItem.Kind.Suite:
                RunSequence(StepsOf(item.Group!));
                break;
            case MenuItem.Kind.RunAll:
                RunSequence(_suites.SelectMany(s => s.Steps));
                break;
        }
    }

    // Шаги по очереди БЕЗ ввода между ними; первый провал останавливает прогон.
    private void RunSequence(IEnumerable<ScriptStep> steps)
    {
        foreach (var step in steps)
        {
            if (!_runStep(step))
            {
                Ui.Line($"[X] stopped: '{step.Name}' failed.", ConsoleColor.Red);
                return;
            }
        }
    }

    private IReadOnlyList<ScriptStep> StepsOf(string group) =>
        _suites.First(s => s.Group == group).Steps;

    private void Draw()
    {
        Ui.Clear();
        Console.WriteLine();
        Console.WriteLine("  TestRunner orchestrator   (Up/Down: move   Enter: run   q: quit)");
        Console.WriteLine("  ================================================================");
        Console.WriteLine();

        for (var i = 0; i < _items.Count; i++)
            DrawItem(_items[i], i == _cursor);

        Console.WriteLine();
    }

    private void DrawItem(MenuItem item, bool selected)
    {
        var (indent, text) = item.ItemKind switch
        {
            MenuItem.Kind.RunAll => ("  ", item.Label),
            MenuItem.Kind.Suite  => ("  ", $"[{item.Label}]"),
            _                    => ("      ", item.Label),
        };

        var prevFg = Console.ForegroundColor;
        var prevBg = Console.BackgroundColor;
        if (selected)
            Console.BackgroundColor = ConsoleColor.DarkGray;
        Console.ForegroundColor = ColorOf(item);
        Console.WriteLine($"{(selected ? "> " : "  ")}{indent}{text}");
        Console.ForegroundColor = prevFg;
        Console.BackgroundColor = prevBg;
    }

    private ConsoleColor ColorOf(MenuItem item) => item.ItemKind switch
    {
        MenuItem.Kind.Step  => _status.ColorFor(item.Step!.Id),
        MenuItem.Kind.Suite => Aggregate(StepsOf(item.Group!)),
        _                   => Aggregate(_suites.SelectMany(s => s.Steps)),
    };

    // Агрегат статуса сьюта/RUN ALL: любой красный -> красный; все зелёные ->
    // зелёный; иначе синий (нейтральный/не запускался).
    private ConsoleColor Aggregate(IEnumerable<ScriptStep> steps)
    {
        var colors = steps.Select(s => _status.ColorFor(s.Id)).ToList();
        if (colors.Count == 0) return ConsoleColor.Blue;
        if (colors.Any(c => c == ConsoleColor.Red)) return ConsoleColor.Red;
        return colors.All(c => c == ConsoleColor.Green) ? ConsoleColor.Green : ConsoleColor.Blue;
    }
}
