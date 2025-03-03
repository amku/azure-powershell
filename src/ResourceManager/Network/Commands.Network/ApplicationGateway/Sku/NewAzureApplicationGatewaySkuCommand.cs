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

using System.Management.Automation;
using Microsoft.Azure.Commands.Network.Models;
using MNM = Microsoft.Azure.Management.Network.Models;

namespace Microsoft.Azure.Commands.Network
{
    [Cmdlet(VerbsCommon.New, "AzureRMApplicationGatewaySku"), OutputType(typeof(PSApplicationGatewaySku))]
    public class NewAzureApplicationGatewaySkuCommand : AzureApplicationGatewaySkuBase
    {
        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            PSApplicationGatewaySku sku = new PSApplicationGatewaySku()
                {
                    Name = this.Name,
                    Tier = this.Tier,
                    Capacity = this.Capacity
                };

            WriteObject(sku);
        }
    }
}
