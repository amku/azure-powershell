﻿//  
// Copyright (c) Microsoft.  All rights reserved.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

namespace Microsoft.Azure.Commands.ApiManagement.Commands
{
    using System.Management.Automation;
    using Microsoft.Azure.Commands.ApiManagement.Models;

    [Cmdlet(VerbsCommon.Add, "AzureRMApiManagementRegion"), OutputType(typeof(PsApiManagement))]
    public class AddAzureApiManagementRegion : AzureApiManagementCmdletBase
    {
        [Parameter(
          ValueFromPipeline = true,
          Mandatory = true,
          HelpMessage = "PsApiManagement instance to add additional deployment region to.")]
        [ValidateNotNull]
        public PsApiManagement ApiManagement { get; set; }

        [Parameter(
            ValueFromPipelineByPropertyName = false, 
            Mandatory = true, 
            HelpMessage = "Location of the new deployment region.")]

        [ValidateNotNullOrEmpty]
        [ValidateSet(
            "North Central US", "South Central US", "Central US", "West Europe", "North Europe", "West US", "East US",
            "East US 2", "Japan East", "Japan West", "Brazil South", "Southeast Asia", "East Asia", "Australia East",
            "Australia Southeast", IgnoreCase = false)]
        public string Location { get; set; }

        [Parameter(
            ValueFromPipelineByPropertyName = false,
            Mandatory = false,
            HelpMessage = "Tier of the deployment region. Valid values are Developer, Standard and Premium. Default value is Developer.")]
        public PsApiManagementSku? Sku { get; set; }

        [Parameter(
            ValueFromPipelineByPropertyName = false,
            Mandatory = false,
            HelpMessage = "Sku capacity of the deployment region. Default value is 1.")]
        public int? Capacity { get; set; }

        [Parameter(
            ValueFromPipelineByPropertyName = false,
            Mandatory = false,
            HelpMessage = "Virtual network configuration. Default value is $null.")]
        public PsApiManagementVirtualNetwork VirtualNetwork { get; set; }

        protected override void ProcessRecord()
        {
            ExecuteCmdLetWrap(
                () =>
                {
                    ApiManagement.AddRegion(Location, Sku ?? PsApiManagementSku.Developer, Capacity ?? 1, VirtualNetwork);

                    return ApiManagement;
                },
                passThru: true);
        }
    }
}