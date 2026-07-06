using System.Reflection;
using Orchestrator.Models;

namespace Orchestrator.Core;

// Holds the live host/vm models (draft: no json file yet). Always works over
// one CurrentHost and one CurrentVm. Resolves state.host.X / state.vm.X by
// reflecting the property named X off the current model. Flat <<set::>> pairs
// still land in a string map for anything that isn't a model field.
internal sealed class StateKeeper
{
    private readonly List<HostInfo> _hosts = new();
    private readonly Dictionary<string, string> _flat = new(StringComparer.OrdinalIgnoreCase);

    public HostInfo? CurrentHost { get; private set; }
    public VmInfo? CurrentVm { get; private set; }

    public HostInfo NewHost()
    {
        var host = new HostInfo();
        _hosts.Add(host);
        CurrentHost = host;
        return host;
    }

    public void SetCurrentVm(string name)
    {
        if (CurrentHost is not null && CurrentHost.Vms.TryGetValue(name, out var vm))
            CurrentVm = vm;
    }

    public bool TryGet(string key, out string value)
    {
        value = "";

        if (key.StartsWith("state.host.", StringComparison.OrdinalIgnoreCase))
            return TryReflect(CurrentHost, key.Substring("state.host.".Length), out value);
        if (key.StartsWith("state.vm.", StringComparison.OrdinalIgnoreCase))
            return TryReflect(CurrentVm, key.Substring("state.vm.".Length), out value);

        if (_flat.TryGetValue(key, out var stored))
        {
            value = stored ?? "";
            return true;
        }
        return false;
    }

    public void Set(string key, string value)
    {
        if (key.StartsWith("state.host.", StringComparison.OrdinalIgnoreCase))
        {
            if (TrySetReflect(CurrentHost, key.Substring("state.host.".Length), value))
                return;
        }
        else if (key.StartsWith("state.vm.", StringComparison.OrdinalIgnoreCase))
        {
            if (TrySetReflect(CurrentVm, key.Substring("state.vm.".Length), value))
                return;
        }

        _flat[key] = value;
    }

    private static bool TryReflect(object? model, string propName, out string value)
    {
        value = "";
        var prop = FindProp(model, propName);
        if (prop is null)
            return false;
        value = prop.GetValue(model)?.ToString() ?? "";
        return true;
    }

    private static bool TrySetReflect(object? model, string propName, string value)
    {
        var prop = FindProp(model, propName);
        if (prop is null || !prop.CanWrite)
            return false;
        prop.SetValue(model, value);
        return true;
    }

    private static PropertyInfo? FindProp(object? model, string propName)
    {
        if (model is null)
            return null;
        return model.GetType().GetProperty(propName,
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
    }
}
