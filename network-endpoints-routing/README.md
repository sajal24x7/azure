This has the bicep code for completing [this](https://learn.microsoft.com/en-in/training/modules/configure-network-routing-endpoints/7-simulation-routing) exercise.

This templates creates:
1. 1 VNet with 2 subnets
2. 2 VMs in the 2 subnets with public and private IPs
3. NSG to allow RDP access

The additional requirements are done through PowerShell commands
- Configure Azure DNS for internal name resolution. Ensure internal Azure virtual machines names and IP addresses can be resolved.
- Configure Azure DNS for external name resolution. Ensure a publicly available domain name can be resolved by external queries.

```powershell

```