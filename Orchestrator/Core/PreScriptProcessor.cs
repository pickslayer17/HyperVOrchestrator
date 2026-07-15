using Orchestrator.Config;
using Orchestrator.Core.Decorators;
using Orchestrator.Executors;

namespace Orchestrator.Core;

internal sealed class PreScriptProcessor
{
    private readonly VersionDecorator _versionDecorator;
    private readonly InjectDecorator _injectDecorator;
    private readonly InterpolateDecorator _interpolateDecorator;
    private readonly ParamsWrapDecorator _paramsWrapDecorator;
    private readonly RootPriviledgeWrapDecorator _rootPriviledgeWrapDecorator;
    private readonly TargetWrapDecorator _targetWrapDecorator;

    public PreScriptProcessor(string scriptsRoot, AppConfig config, StateKeeper stateKeeper, PowerShellHost host)
    {
        var configValues = ConfigFlattener.Flatten(config);
        _versionDecorator = new VersionDecorator(host.MajorVersion);
        _injectDecorator = new InjectDecorator(scriptsRoot);
        _interpolateDecorator = new InterpolateDecorator(configValues, stateKeeper);
        _paramsWrapDecorator = new ParamsWrapDecorator();
        _rootPriviledgeWrapDecorator = new RootPriviledgeWrapDecorator();
        _targetWrapDecorator = new TargetWrapDecorator(stateKeeper, config.Credentials.User, config.Credentials.Password);
    }

    public string Process(string script, IReadOnlyDictionary<string, string>? args = null, ExecutorTarget? executorTarget = null)
    {
        var decoratableScript = script;
        decoratableScript = _versionDecorator.Format(decoratableScript);
        decoratableScript = _injectDecorator.Format(decoratableScript);
        decoratableScript = _interpolateDecorator.Format(decoratableScript);
        decoratableScript = _paramsWrapDecorator.Format(decoratableScript, args);
        var systemVariables = SystemVariablesReader.Read(decoratableScript);

        var isTargetVm = executorTarget.HasValue ? executorTarget.Value == ExecutorTarget.VM : systemVariables.IsTargetVm;
        decoratableScript = systemVariables.IsRootPriviledges ? _rootPriviledgeWrapDecorator.Format(decoratableScript) : decoratableScript;
        decoratableScript = isTargetVm ? _targetWrapDecorator.Format(decoratableScript) : decoratableScript;

        var result = decoratableScript;
        return result;
    }
}