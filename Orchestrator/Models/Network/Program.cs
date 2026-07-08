using ConsoleApp1.NetworkModel;

var host = new Host();
var configNatName = "Nat";
//we dont know when host was created and what data it contains
// we know only that host object exists and config provides values

// 1. check/add Nat. should be done always. without it impossible to continue. dependings = all
if (host.NatNet == null)
{
    Net netInfo = null;
    if (host.NetExecutor.NatExists(configNatName))
    {
        netInfo = host.NetExecutor.GetNetInfo(configNatName);
    }
    else
    {
        netInfo = host.NetExecutor.CreateNatNet(configNatName);
    }
    netInfo.HostNetInterface = host.NetExecutor.GetHostNetInterfaceInfo(configNatName);
    host.NatNetInterface = netInfo.HostNetInterface;
}//error - throw

// 2. set static ip for host and vm in Nat
// vm set its static ip through its own NetExecutor

// 3. Start python. dependings = all python steps, 5, for example
if (host.PythonExecutor == null)
{
    if (host.PythonExecutor.IsAlive())
    {
    }
    else
    {
    }
}

// 4. Get Host nat free ip for proxy
var freeHostNatPort = host.NetExecutor.GetFreePort(host.NatNet.Name);

// 5. Python start listen on this port
host.PythonExecutor.StartProxyListening($"{host.NatNetInterface}{freeHostNatPort}");

//6. set up proxy on VM(vm netexecutor) to host nat ip: proxyport

// 7. Get host global free port. fwdPort. set to host model

//8 python listen to this port and forward to vm nat ip: 3389 (RDP)

// 9. allow rdp on vm(could be donw through orchestrator
