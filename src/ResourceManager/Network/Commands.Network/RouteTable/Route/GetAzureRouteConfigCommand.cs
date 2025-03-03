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

using System.Linq;
using System.Management.Automation;
using Microsoft.Azure.Commands.Network.Models;

namespace Microsoft.Azure.Commands.Network
{
    [Cmdlet(VerbsCommon.Get, "AzureRMRouteConfig"), OutputType(typeof(PSRoute))]
    public class GetAzureRouteConfigCommand : NetworkBaseCmdlet
    {
        [Parameter(
           Mandatory = false,
           HelpMessage = "The name of the route")]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            HelpMessage = "The RouteTable")]
        public PSRouteTable RouteTable { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            var routes = this.RouteTable.Routes;
            
            if (!string.IsNullOrEmpty(this.Name))
            {
                var route =
                    routes.First(
                        resource =>
                            string.Equals(resource.Name, this.Name, System.StringComparison.CurrentCultureIgnoreCase));

                WriteObject(route);
            }
            else
            {
                WriteObject(routes, true);
            }
        }
    }
}
