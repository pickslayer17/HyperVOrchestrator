using Orchestrator.FSModels;

namespace Orchestrator.Executors;

public class PythonExecutor
{
    public bool IsAlive()
    {
        //script
        return true;
    }

    public void Start()
    {
        //script
    }

    public void StartProxy(string ip, int port)
    {
        //script to python
    }

    public void StartForward(string bindIp, int listenPort, string targetIp, int targetPort)
    {
        //script to python
    }

    public bool GetProxyAlive()
    {
        //script to python: is_alive
        return false;
    }

    public ConnectionsFSModel GetAllConnections()
    {
        //script to python: get_connections
        return new ConnectionsFSModel();
    }
}
