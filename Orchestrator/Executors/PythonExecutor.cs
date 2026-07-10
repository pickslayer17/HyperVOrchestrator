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
}
