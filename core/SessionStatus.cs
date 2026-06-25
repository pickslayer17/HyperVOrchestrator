namespace Orchestrator;

// Статус шагов в ТЕКУЩЕЙ сессии (по ScriptStep.Id).
// Зелёный — успех, красный — провал, синий — ещё не запускался.
// Это не персистентный state (тот — в StateStore), а просто подсветка меню.
internal sealed class SessionStatus
{
    private readonly HashSet<string> _succeeded = [];
    private readonly HashSet<string> _failed = [];

    public void MarkOk(string id)
    {
        _succeeded.Add(id);
        _failed.Remove(id);
    }

    public void MarkFailed(string id)
    {
        _failed.Add(id);
        _succeeded.Remove(id);
    }

    public ConsoleColor ColorFor(string id) =>
        _succeeded.Contains(id) ? ConsoleColor.Green :
        _failed.Contains(id) ? ConsoleColor.Red :
        ConsoleColor.Blue;
}
