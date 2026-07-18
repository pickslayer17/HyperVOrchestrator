using System.Net;
using Orchestrator.Executors;

namespace Orchestrator.Models.NetWorkModels;

public class PythonServer
{
    public PythonExecutor PythonExecutor;
    public bool Alive { get; set; }
    public int ActiveConnections { get; set; }
    public List<IPEndPoint> ProxyConnections = new();
    public Dictionary<IPEndPoint, IPEndPoint> DnsConnections = new();
}
