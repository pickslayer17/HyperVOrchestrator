using System.Reflection;
using Orchestrator.Models.Azure;
using Orchestrator.Models.NetWorkModels;

namespace Orchestrator.Core;

internal sealed class StateKeeper
{
    public Host? CurrentHost { get; private set; }
    public VM? CurrentVm { get; private set; }
    public AgentPool? AgentPool { get; set; }

    public void SetCurrentHost(Host host)
    {
        CurrentHost = host;
    }

    public void SetCurrentVm(VM vm)
    {
        CurrentVm = vm;
    }

    public bool TryGet(string key, out string value)
    {
        value = "";

        if (key.StartsWith("state.host.", StringComparison.OrdinalIgnoreCase))
            return TryReadPath(CurrentHost, key["state.host.".Length..], out value);
        if (key.StartsWith("state.vm.", StringComparison.OrdinalIgnoreCase))
            return TryReadPath(CurrentVm, key["state.vm.".Length..], out value);

        return false;
    }

    private static bool TryReadPath(object? model, string path, out string value)
    {
        value = "";
        var current = model;
        foreach (var part in path.Split('.'))
        {
            if (current is null)
                return false;
            current = ReadMember(current, part);
        }
        value = current?.ToString() ?? "";
        return true;
    }

    private static object? ReadMember(object model, string name)
    {
        var type = model.GetType();
        var flags = BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase;

        var property = type.GetProperty(name, flags);
        if (property is not null)
            return property.GetValue(model);

        var field = type.GetField(name, flags);
        if (field is not null)
            return field.GetValue(model);

        return null;
    }
}
