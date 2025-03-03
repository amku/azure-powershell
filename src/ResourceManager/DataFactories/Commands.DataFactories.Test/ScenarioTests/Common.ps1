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
Gets valid resource group name
#>
function Get-ResourceGroupName
{
    return getAssetName
}

<#
.SYNOPSIS
Gets valid data factory name
#>
function Get-DataFactoryName
{
    return getAssetName
}

<#
.SYNOPSIS
Gets the default location for a provider
#>
function Get-ProviderLocation($provider)
{
    # A Dogfood data center for ADF cmdlet mock testing
    "East US 2"
}

<#
.SYNOPSIS
Cleans the created data factory
#>
function Clean-DataFactory($rgname, $dfname)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback) {
        Remove-AzureRMDataFactory -ResourceGroupName $rgname -Name $dfname -Force
    }
}

<#
.SYNOPSIS
Cleans the created tags
#>
function Clean-Tags
{
    Get-AzureRMTag | Remove-AzureRMTag -Force
}
