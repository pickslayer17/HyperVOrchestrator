using System.Net;
using Orchestrator.Enums;
using Orchestrator.Executors;

namespace Orchestrator.Models.NetWorkModels;

public class VM
{
    public string Name;
    public OfficeApp OfficeApp;
    public bool Running;
    public NetInterface NatNetInterface;
    public IPEndPoint? ProxyAddress;
    public IPEndPoint? DnsAddress;
    public bool SingBoxRunning;

    public NetExecutor NetExecutor;
    public SingBoxExecutor SingBoxExecutor;
}
