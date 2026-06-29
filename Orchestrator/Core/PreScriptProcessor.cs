using Orchestrator.Config;
using Orchestrator.Core.Decorators;

namespace Orchestrator.Core;

internal sealed class PreScriptProcessor
{
    private readonly VersionDecorator _versionDecorator;
    private readonly InjectDecorator _injectDecorator;
    private readonly InterpolateDecorator _interpolateDecorator;
    private readonly TargetWrapDecorator _targetWrapDecorator;

    public PreScriptProcessor(string repoRoot, AppConfig config, StateKeeper stateKeeper, PowerShellHost host)
    {
        var configValues = ConfigFlattener.Flatten(config);
        _versionDecorator = new VersionDecorator(host.MajorVersion);
        _injectDecorator = new InjectDecorator(repoRoot);
        _interpolateDecorator = new InterpolateDecorator(configValues, stateKeeper);
        _targetWrapDecorator = new TargetWrapDecorator(config.Vm.Name, config.Credentials.User, config.Credentials.Password);
    }

    public string Process(string script)
    {
        var versioned = _versionDecorator.Format(script);
        var injected = _injectDecorator.Format(versioned);
        var interpolated = _interpolateDecorator.Format(injected);
        var targetWrapped = _targetWrapDecorator.Format(interpolated);
        var result = targetWrapped;
        return result;
    }
}
