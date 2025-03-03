﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Tests creating a public Load balancer.
#>
function Test-LoadBalancerCRUD-Public
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating an internal Load balancer with dynamic ip.
#>
function Test-LoadBalancerCRUD-InternalDynamic
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0]
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-NotNull $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating an internal Load balancer with static ip.
#>
function Test-LoadBalancerCRUD-InternalStatic
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0] -PrivateIpAddress "10.0.1.5"
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-AreEqual "10.0.1.5" $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating a public Load balancer without InboundNAtRule
#>
function Test-LoadBalancerCRUD-PublicNoInboundNATRule
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating an internal Load balancer using resource ids
#>
function Test-LoadBalancerCRUD-InternalUsingId
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname
        
        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName	
        Assert-AreEqual $expectedLb.Name $actualLb.Name	
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        
        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath
        
        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id
        
        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
        
        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag
        
        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating a public Load balancer using resource ids
#>
function Test-LoadBalancerCRUD-PublicUsingId
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddressId $publicip.Id
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname
        
        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName	
        Assert-AreEqual $expectedLb.Name $actualLb.Name	
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        
        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name
        
        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath
        
        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id
        
        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
        
        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag
        
        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating a public Load balancer without a lb rule
#>
function Test-LoadBalancerCRUD-PublicNoLbRule
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $actualLb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule
        
        $expectedLb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        # Verification
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        # List
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        
        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}


<#
.SYNOPSIS
Tests creating new simple Load balancer and edit child resources using config cmdlets
#>
function Test-LoadBalancerChildResource
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname
        
        # Test FrontendConfig cmdlets
        $frontendName2 = Get-ResourceName
        $lb = $lb | Add-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName2 -Subnet $vnet.Subnets[0]

        Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
        Assert-AreEqual $frontendName2 $lb.FrontendIPConfigurations[1].Name
        Assert-AreEqual "Dynamic" $lb.FrontendIPConfigurations[1].PrivateIPAllocationMethod
        Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[1].Subnet.Id

        $lb = $lb | Set-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName2 -Subnet $vnet.Subnets[0] -PrivateIpAddress "10.0.1.5"
        Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
        Assert-AreEqual $frontendName2 $lb.FrontendIPConfigurations[1].Name
        Assert-AreEqual "Static" $lb.FrontendIPConfigurations[1].PrivateIPAllocationMethod
        Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[1].Subnet.Id
        Assert-AreEqual "10.0.1.5" $lb.FrontendIPConfigurations[1].PrivateIpAddress

        $frontendIpconfig = $lb | Get-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName2
        $frontendIpconfigList = $lb | Get-AzureRMLoadBalancerFrontendIpConfig
        Assert-AreEqual 2 @($frontendIpconfigList).Count
        Assert-AreEqual $frontendName $frontendIpconfigList[0].Name
        Assert-AreEqual $frontendName2 $frontendIpconfigList[1].Name
        Assert-AreEqual $frontendIpconfig.Name $frontendIpconfigList[1].Name

        $lb = $lb | Remove-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName2
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count
        Assert-AreEqual $frontendName $lb.FrontendIPConfigurations[0].Name

        # Test BackendAddressPool cmdlets
        $backendAddressPoolName2 = Get-ResourceName
        $lb =  Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName2 | Set-AzureRMLoadBalancer

        Assert-AreEqual 2 @($lb.BackendAddressPools).Count
        Assert-AreEqual $backendAddressPoolName2 $lb.BackendAddressPools[1].Name

        $backendAddressPoolConfig = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname| Get-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName2
        $backendAddressPoolConfigList = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerBackendAddressPoolConfig
        Assert-AreEqual 2 @($backendAddressPoolconfigList).Count
        Assert-AreEqual $backendAddressPoolName $backendAddressPoolConfigList[0].Name
        Assert-AreEqual $backendAddressPoolName2 $backendAddressPoolConfigList[1].Name
        Assert-AreEqual $backendAddressPoolConfig.Name $backendAddressPoolConfigList[1].Name

        $lb =  Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName2 | Set-AzureRMLoadBalancer
        Assert-AreEqual 1 @($lb.BackendAddressPools).Count
        Assert-AreEqual $backendAddressPoolName $lb.BackendAddressPools[0].Name

        # Test Probe cmdlets
        $probeName2 = Get-ResourceName
        $lb =  Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzureRMLoadBalancerProbeConfig -Name $probeName2 -RequestPath healthcheck2.aspx -Protocol http -Port 81 -IntervalInSeconds 16 -ProbeCount 3 | Set-AzureRMLoadBalancer

        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 81 $lb.Probes[1].Port

        $lb =  Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzureRMLoadBalancerProbeConfig -Name $probeName2 -RequestPath healthcheck2.aspx -Protocol http -Port 85 -IntervalInSeconds 16 -ProbeCount 3 | Set-AzureRMLoadBalancer
        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 85 $lb.Probes[1].Port

        $probeConfig = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerProbeConfig -Name $probeName2
        $probeConfigList = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerProbeConfig
        Assert-AreEqual 2 @($probeConfigList).Count
        Assert-AreEqual $probeName $probeConfigList[0].Name
        Assert-AreEqual $probeName2 $probeConfigList[1].Name
        Assert-AreEqual $probeConfig.Name $probeConfigList[1].Name

        $lb =  Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzureRMLoadBalancerProbeConfig -Name $probeName2 | Set-AzureRMLoadBalancer
        Assert-AreEqual 1 @($lb.Probes).Count
        Assert-AreEqual $probeName $lb.Probes[0].Name

        # Test InboundNatRule cmdlets
        $inboundNatRuleName2 = Get-ResourceName
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPort 3350 -BackendPort 3350 -IdleTimeoutInMinutes 17 -EnableFloatingIP | Set-AzureRMLoadBalancer
        
        Assert-AreEqual 2 @($lb.InboundNatRules).Count
        Assert-AreEqual $inboundNatRuleName2 $lb.InboundNatRules[1].Name
        Assert-AreEqual 3350 $lb.InboundNatRules[1].FrontendPort
        Assert-AreEqual 3350 $lb.InboundNatRules[1].BackendPort
        Assert-AreEqual true $lb.InboundNatRules[1].EnableFloatingIP

        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPort 3352 -BackendPort 3351 -IdleTimeoutInMinutes 17 | Set-AzureRMLoadBalancer
        Assert-AreEqual 2 @($lb.InboundNatRules).Count
        Assert-AreEqual $inboundNatRuleName2 $lb.InboundNatRules[1].Name
        Assert-AreEqual 3352 $lb.InboundNatRules[1].FrontendPort
        Assert-AreEqual 3351 $lb.InboundNatRules[1].BackendPort
        Assert-AreEqual false $lb.InboundNatRules[1].EnableFloatingIP

        $inboundNatRuleConfig = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2
        $inboundNatRuleConfigList = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerInboundNatRuleConfig
        Assert-AreEqual 2 @($inboundNatRuleConfigList).Count
        Assert-AreEqual $inboundNatRuleName $inboundNatRuleConfigList[0].Name
        Assert-AreEqual $inboundNatRuleName2 $inboundNatRuleConfigList[1].Name
        Assert-AreEqual $inboundNatRuleConfig.Name $inboundNatRuleConfigList[1].Name

        $lb =  Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 | Set-AzureRMLoadBalancer
        Assert-AreEqual 1 @($lb.InboundNatRules).Count
        Assert-AreEqual $inboundNatRuleName $lb.InboundNatRules[0].Name

        # Test LoadBalancingRule Cmdlets
        $lbruleName2 = Get-ResourceName
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzureRMLoadBalancerRuleConfig -Name $lbruleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -BackendAddressPoolId $lb.BackendAddressPools[0].Id -ProbeId $lb.Probes[0].Id -Protocol Tcp -FrontendPort 82 -BackendPort 83 -IdleTimeoutInMinutes 15 -LoadDistribution SourceIP| Set-AzureRMLoadBalancer
        
        Assert-AreEqual 2 @($lb.LoadBalancingRules).Count
        Assert-AreEqual $lbruleName2 $lb.LoadBalancingRules[1].Name
        Assert-AreEqual 82 $lb.LoadBalancingRules[1].FrontendPort
        Assert-AreEqual 83 $lb.LoadBalancingRules[1].BackendPort
        Assert-AreEqual false $lb.LoadBalancingRules[1].EnableFloatingIP
        Assert-AreEqual "SourceIP" $lb.LoadBalancingRules[1].LoadDistribution

        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzureRMLoadBalancerRuleConfig -Name $lbruleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -BackendAddressPoolId $lb.BackendAddressPools[0].Id -ProbeId $lb.Probes[0].Id -Protocol Tcp -FrontendPort 84 -BackendPort 84 -IdleTimeoutInMinutes 17 -EnableFloatingIP | Set-AzureRMLoadBalancer
        Assert-AreEqual 2 @($lb.LoadBalancingRules).Count
        Assert-AreEqual $lbruleName2 $lb.LoadBalancingRules[1].Name
        Assert-AreEqual 84 $lb.LoadBalancingRules[1].FrontendPort
        Assert-AreEqual 84 $lb.LoadBalancingRules[1].BackendPort
        Assert-AreEqual true $lb.LoadBalancingRules[1].EnableFloatingIP
        Assert-AreEqual "Default" $lb.LoadBalancingRules[1].LoadDistribution

        $lbruleConfig = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerRuleConfig -Name $lbruleName2
        $lbruleConfigList = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzureRMLoadBalancerRuleConfig
        Assert-AreEqual 2 @($inboundNatRuleConfigList).Count
        Assert-AreEqual $lbruleName $lbruleConfigList[0].Name
        Assert-AreEqual $lbruleName2 $lbruleConfigList[1].Name
        Assert-AreEqual $lbruleConfig.Name $lbruleConfigList[1].Name

        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzureRMLoadBalancerRuleConfig -Name $lbruleName2 | Set-AzureRMLoadBalancer
        Assert-AreEqual 1 @($lb.LoadBalancingRules).Count
        Assert-AreEqual $lbruleName $lb.LoadBalancingRules[0].Name

        # Delete
        $deleteLb = $lb | Remove-AzureRMLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating and editing a simple Load balancer 
#>
function Test-LoadBalancerSet
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname
    
        # Test Probe cmdlets
        $probeName2 = Get-ResourceName
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzureRMLoadBalancerProbeConfig -Name $probeName2 -RequestPath healthcheck2.aspx -Protocol http -Port 81 -IntervalInSeconds 16 -ProbeCount 3 | Set-AzureRMLoadBalancer

        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 81 $lb.Probes[1].Port

        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzureRMLoadBalancer
        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 81 $lb.Probes[1].Port

        # Delete
        $deleteLb = $lb | Remove-AzureRMLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating an empty Load balancer 
#>
function Test-CreateEmptyLoadBalancer
{
    # Setup
    $rgname = Get-ResourceGroupName
    $lbName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create empty load balancer
        New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location

        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname
        Assert-AreEqual $lbName $lb.Name
        Assert-AreEqual 0 @($lb.FrontendIpConfigurations).Count
        Assert-AreEqual 0 @($lb.BackendAddressPools).Count
        Assert-AreEqual 0 @($lb.Probes).Count
        Assert-AreEqual 0 @($lb.InboundNatRules).Count
        Assert-AreEqual 0 @($lb.LoadBalancingRules).Count

        # Delete
        $deleteLb = $lb | Remove-AzureRMLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating a Load balancer with NIC references
#>
function Test-LoadBalancer-NicAssociation
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName1 = Get-ResourceName
    $inboundNatRuleName2 = Get-ResourceName
    $lbruleName = Get-ResourceName
    $nicname1 = Get-ResourceName
    $nicname2 = Get-ResourceName
    $nicname3 = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule1 = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName1 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $inboundNatRule2 = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3391 -BackendPort 3392
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule1,$inboundNatRule2 -LoadBalancingRule $lbrule
        
        # Verification of Load Balancer
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-AreEqual $location $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count

        Assert-Null $lb.InboundNatRules[0].BackendIPConfiguration
        Assert-Null $lb.InboundNatRules[1].BackendIPConfiguration
        Assert-AreEqual 0 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        # Create 3 network interfaces and accociate to loadbalancer
        $nic1 = New-AzureRMNetworkInterface -Name $nicname1 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]
        $nic2 = New-AzureRMNetworkInterface -Name $nicname2 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]
        $nic3 = New-AzureRMNetworkInterface -Name $nicname3 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]

        # Associate the nic to the load balancer
        $nic1.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($lb.BackendAddressPools[0]);
        $nic1.IpConfigurations[0].LoadBalancerInboundNatRules.Add($lb.InboundNatRules[0]);
        $nic2.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($lb.BackendAddressPools[0]);
        $nic3.IpConfigurations[0].LoadBalancerInboundNatRules.Add($lb.InboundNatRules[1]);

        # set the nics
        $nic1 = $nic1 | Set-AzureRMNetworkInterface
        $nic2 = $nic2 | Set-AzureRMNetworkInterface
        $nic3 = $nic3 | Set-AzureRMNetworkInterface

        # Verify the Load balancer references
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        Assert-AreEqual $nic1.IpConfigurations[0].Id $lb.InboundNatRules[0].BackendIPConfiguration.Id
        Assert-AreEqual $nic3.IpConfigurations[0].Id $lb.InboundNatRules[1].BackendIPConfiguration.Id
        Assert-AreEqual 2 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests creating a NIC with Loadbalancer references
#>
function Test-LoadBalancer-NicAssociationDuringCreate
{
    # Setup
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName1 = Get-ResourceName
    $inboundNatRuleName2 = Get-ResourceName
    $lbruleName = Get-ResourceName
    $nicname1 = Get-ResourceName
    $nicname2 = Get-ResourceName
    $nicname3 = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        # Create the resource group
        $resourceGroup = New-AzureRMResourceGroup -Name $rgname -Location $rglocation -Tags @{Name = "testtag"; Value = "testval"} 
        
        # Create the Virtual Network
        $subnet = New-AzureRMVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzureRMvirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        # Create the publicip
        $publicip = New-AzureRMPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic

        # Create LoadBalancer
        $frontend = New-AzureRMLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzureRMLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzureRMLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule1 = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName1 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $inboundNatRule2 = New-AzureRMLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3391 -BackendPort 3392
        $lbrule = New-AzureRMLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule1,$inboundNatRule2 -LoadBalancingRule $lbrule
        
        # Verification of Load Balancer
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-AreEqual $location $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count

        Assert-Null $lb.InboundNatRules[0].BackendIPConfiguration
        Assert-Null $lb.InboundNatRules[1].BackendIPConfiguration
        Assert-AreEqual 0 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        # Create 3 network interfaces and accociate to loadbalancer
        $nic1 = New-AzureRMNetworkInterface -Name $nicname1 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0]
        $nic2 = New-AzureRMNetworkInterface -Name $nicname2 -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -LoadBalancerBackendAddressPoolId $lb.BackendAddressPools[0].Id
        $nic3 = New-AzureRMNetworkInterface -Name $nicname3 -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -LoadBalancerInboundNatRuleId $lb.InboundNatRules[1].Id

        # set the nics
        $nic1 = $nic1 | Set-AzureRMNetworkInterface
        $nic2 = $nic2 | Set-AzureRMNetworkInterface
        $nic3 = $nic3 | Set-AzureRMNetworkInterface

        # Verify the Load balancer references
        $lb = Get-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname

        Assert-AreEqual $nic1.IpConfigurations[0].Id $lb.InboundNatRules[0].BackendIPConfiguration.Id
        Assert-AreEqual $nic3.IpConfigurations[0].Id $lb.InboundNatRules[1].BackendIPConfiguration.Id
        Assert-AreEqual 2 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        # Delete
        $deleteLb = Remove-AzureRMLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzureRMLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}