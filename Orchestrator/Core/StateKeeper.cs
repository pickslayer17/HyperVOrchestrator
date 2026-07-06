using System.Reflection;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class StateKeeper
{
    private readonly List<HostInfo> _hosts = new();
    private readonly Dictionary<string, string> _flatState = new(StringComparer.OrdinalIgnoreCase);

    public HostInfo? CurrentHost { get; private set; }
    public VmInfo? CurrentVm { get; private set; }

    public void AddHost(HostInfo hostInfo)
    {
        _hosts.Add(hostInfo);
        CurrentHost = hostInfo;
    }

    public void SetCurrentHost(HostInfo hostInfo)
    {
        if (_hosts.Contains(hostInfo))
            CurrentHost = hostInfo;
    }

    public void SetCurrentVm(string vmName)
    {
        if (CurrentHost is not null && CurrentHost.Vms.TryGetValue(vmName, out var vm))
            CurrentVm = vm;
    }

    public bool TryGet(string key, out string value)
    {
        value = "";

        if (key.StartsWith("state.host.", StringComparison.OrdinalIgnoreCase))
            return TryReadProperty(CurrentHost, key.Substring("state.host.".Length), out value);
        if (key.StartsWith("state.vm.", StringComparison.OrdinalIgnoreCase))
            return TryReadProperty(CurrentVm, key.Substring("state.vm.".Length), out value);

        if (_flatState.TryGetValue(key, out var storedValue))
        {
            value = storedValue ?? "";
            return true;
        }
        return false;
    }

    public void Set(string key, string value)
    {
        if (key.StartsWith("state.host.", StringComparison.OrdinalIgnoreCase))
        {
            if (TryWriteProperty(CurrentHost, key.Substring("state.host.".Length), value))
                return;
        }
        else if (key.StartsWith("state.vm.", StringComparison.OrdinalIgnoreCase))
        {
            if (TryWriteProperty(CurrentVm, key.Substring("state.vm.".Length), value))
                return;
        }

        _flatState[key] = value;
    }

    private static bool TryReadProperty(object? model, string propertyName, out string value)
    {
        value = "";
        var property = FindProperty(model, propertyName);
        if (property is null)
            return false;
        value = property.GetValue(model)?.ToString() ?? "";
        return true;
    }

    private static bool TryWriteProperty(object? model, string propertyName, string value)
    {
        var property = FindProperty(model, propertyName);
        if (property is null || !property.CanWrite)
            return false;
        property.SetValue(model, value);
        return true;
    }

    private static PropertyInfo? FindProperty(object? model, string propertyName)
    {
        if (model is null)
            return null;
        return model.GetType().GetProperty(propertyName,
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
    }
}
