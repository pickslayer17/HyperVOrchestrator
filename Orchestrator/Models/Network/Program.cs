using ConsoleApp1.NetworkModel;

var host = new Host();
var configNatName = "Nat";
//we dont know when host was created and what data it contains
// we know only that host object exists and config provides values

// 1. check/add Nat. should be done always. without it impossible to continue. dependings = all
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
host.NetExecutor.SetStaticIp(host.NatNet.Name);
foreach (var vm in host.VMs)
    vm.NatNetInterface = vm.NetExecutor.SetStaticIp(host.NatNet.Name);

// 3. Start python. dependings = all python steps, 5, for example
if (!host.PythonExecutor.IsAlive())
    host.PythonExecutor.Start();

// 4. Get Host nat free ip for proxy
var proxyPort = host.NetExecutor.GetFreePort(host.NatNet.Name);

// 5. Python start listen on this port
host.PythonExecutor.StartProxy(host.NatNetInterface.IP, proxyPort);
var proxyAddress = $"{host.NatNetInterface.IP}:{proxyPort}";

foreach (var vm in host.VMs)
{
    //6. set up proxy on VM(vm netexecutor) to host nat ip: proxyport
    vm.ProxyAddress = proxyAddress;
    vm.NetExecutor.SetProxy(proxyAddress);

    // 7. Get host global free port. fwdPort. set to host model
    var fwdPort = host.NetExecutor.GetFreePort(host.GlobalNetInterface.Alias);
    host.FwdIpdsAndPorts[vm.NatNetInterface.IP] = fwdPort;

    //8 python listen to this port and forward to vm nat ip: 3389 (RDP)
    var vmRdpPort = vm.NetExecutor.GetRdpPort();
    host.PythonExecutor.StartForward(fwdPort, vm.NatNetInterface.IP, vmRdpPort);

    // 9. allow rdp on vm(could be donw through orchestrator
    vm.NetExecutor.EnableRdp();
}
