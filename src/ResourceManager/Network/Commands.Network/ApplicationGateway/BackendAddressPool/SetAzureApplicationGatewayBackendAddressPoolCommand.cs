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
using System.Linq;
using System.Management.Automation;
using Microsoft.Azure.Commands.Network.Models;
using MNM = Microsoft.Azure.Management.Network.Models;

namespace Microsoft.Azure.Commands.Network
{
    [Cmdlet(VerbsCommon.Set, "AzureRMApplicationGatewayBackendAddressPool"), OutputType(typeof(PSApplicationGateway))]
    public class SetAzureApplicationGatewayBackendAddressPoolCommand : AzureApplicationGatewayBackendAddressPoolBase
    {
        [Parameter(
             Mandatory = true,
             ValueFromPipeline = true,
             HelpMessage = "The applicationGateway")]
        public PSApplicationGateway ApplicationGateway { get; set; }
        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            var backendAddressPool = this.ApplicationGateway.BackendAddressPools.SingleOrDefault
                (resource => string.Equals(resource.Name, this.Name, System.StringComparison.CurrentCultureIgnoreCase));

            if (backendAddressPool == null)
            {
                throw new ArgumentException("Backend address pool with the specified name does not exist");
            }

            var newbackendAddressPool = base.NewObject();

            this.ApplicationGateway.BackendAddressPools.Remove(backendAddressPool);
            this.ApplicationGateway.BackendAddressPools.Add(newbackendAddressPool);

            WriteObject(this.ApplicationGateway);
        }
    }
}
