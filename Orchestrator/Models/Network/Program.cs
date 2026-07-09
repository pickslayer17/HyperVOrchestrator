using ConsoleApp1.NetworkModel;

var host = new Host();
var vm = host.VMs[0];
var configNatName = "Nat";
var fwdListenIp = "0.0.0.0";
//we dont know when host was created and what data it contains
// we know only that host object exists and config provides values

// 1. check/add Nat. should be done always. without it impossible to continue. dependings = all
// a host
// b host.NetExecutor
// c configNatName
if (host.NatNet == null)
{
    var netInfo = host.NetExecutor.NatExists(configNatName)
        ? host.NetExecutor.GetNetInfo(configNatName)
        : host.NetExecutor.CreateNatNet(configNatName);

    netInfo.HostNetInterface = host.NetExecutor.GetHostNetInterfaceInfo(configNatName);
    host.NatNet = netInfo;
    host.NatNetInterface = netInfo.HostNetInterface;
}
if (host.NatNet == null)
    throw new InvalidOperationException($"Nat '{configNatName}' is not available.");

// 2. set static ip for host and vm in Nat
// vm set its static ip through its own NetExecutor
// a host.NatNet (1)
// b host.NetExecutor
// c vm.NetExecutor
host.NetExecutor.SetStaticIp(host.NatNet.Alias);
vm.NatNetInterface = vm.NetExecutor.SetStaticIp(host.NatNet.Alias);

// 3. Start python. dependings = all python steps, 5, for example
// a host.PythonExecutor
if (!host.PythonExecutor.IsAlive())
    host.PythonExecutor.Start();

// 4. Get Host nat free ip for proxy
// a host
// b host.NatNet (1)
var proxyPort = host.NetExecutor.GetFreePort(host.NatNet.Alias);

// 5. Python start listen on this port
// a python running (3)
// b host.NatNetInterface.IP (1)
// c proxyPort (4)
host.PythonExecutor.StartProxy(host.NatNetInterface.IP, proxyPort);
var proxyAddress = $"{host.NatNetInterface.IP}:{proxyPort}";

//6. set up proxy on VM(vm netexecutor) to host nat ip: proxyport
// a vm.NetExecutor
// b vm static ip (2)
// c proxyAddress (5)
vm.ProxyAddress = proxyAddress;
vm.NetExecutor.SetProxy(proxyAddress);

// 7. Get host global free port. fwdPort. set to host model
// a host
// b host.GlobalNetInterface
var fwdPort = host.NetExecutor.GetFreePort(host.GlobalNetInterface.Alias);

//8 python listen to this port and forward to vm nat ip: 3389 (RDP)
// a python running (3)
// b fwdPort (7)
// c vm.NatNetInterface.IP (2)
// d fwdListenIp
host.PythonExecutor.StartForward(fwdListenIp, fwdPort, vm.NatNetInterface.IP, 3389);
host.FwdIpdsAndPorts[vm.NatNetInterface.IP] = fwdPort;

// 9. allow rdp on vm(could be donw through orchestrator
// a vm.NetExecutor
vm.NetExecutor.EnableRdp();
