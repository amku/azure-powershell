﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

using System;
using System.Management.Automation;
using AutoMapper;
using Microsoft.Azure.Commands.Tags.Model;
using Microsoft.Azure.Management.Network;
using Microsoft.Azure.Commands.Network.Models;
using Microsoft.Azure.Commands.Resources.Models;
using MNM = Microsoft.Azure.Management.Network.Models;

namespace Microsoft.Azure.Commands.Network
{
    [Cmdlet(VerbsCommon.Set, "AzureRMNetworkInterface"), OutputType(typeof(PSNetworkInterface))]
    public class SetAzureNetworkInterfaceCommand : NetworkInterfaceBaseCmdlet
    {
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            HelpMessage = "The NetworkInterface")]
        public PSNetworkInterface NetworkInterface { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            if (!this.IsNetworkInterfacePresent(this.NetworkInterface.ResourceGroupName, this.NetworkInterface.Name))
            {
                throw new ArgumentException(Microsoft.Azure.Commands.Network.Properties.Resources.ResourceNotFound);
            }

            // Verify if PublicIpAddress is empty
            foreach(var ipconfig in NetworkInterface.IpConfigurations)
            {
                if (ipconfig.PublicIpAddress != null &&
                    string.IsNullOrEmpty(ipconfig.PublicIpAddress.Id))
                {
                    ipconfig.PublicIpAddress = null;
                }
            }
            
            // Map to the sdk object
            var networkInterfaceModel = Mapper.Map<MNM.NetworkInterface>(this.NetworkInterface);
            networkInterfaceModel.Type = Microsoft.Azure.Commands.Network.Properties.Resources.NetworkInterfaceType;
            networkInterfaceModel.Tags = TagsConversionHelper.CreateTagDictionary(this.NetworkInterface.Tag, validate: true);

            this.NetworkInterfaceClient.CreateOrUpdate(this.NetworkInterface.ResourceGroupName, this.NetworkInterface.Name, networkInterfaceModel);

            var getNetworkInterface = this.GetNetworkInterface(this.NetworkInterface.ResourceGroupName, this.NetworkInterface.Name);
            WriteObject(getNetworkInterface);
        }
    }
}
