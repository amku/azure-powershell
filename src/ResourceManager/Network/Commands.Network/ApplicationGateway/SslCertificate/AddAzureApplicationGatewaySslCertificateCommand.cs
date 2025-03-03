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
using System.Security.Cryptography.X509Certificates;
using MNM = Microsoft.Azure.Management.Network.Models;

namespace Microsoft.Azure.Commands.Network
{
    [Cmdlet(VerbsCommon.Add, "AzureRMApplicationGatewaySslCertificate"), OutputType(typeof(PSApplicationGateway))]
    public class AddAzureApplicationGatewaySslCertificateCommand : AzureApplicationGatewaySslCertificateBase
    {
        [Parameter(
             Mandatory = true,
             ValueFromPipeline = true,
             HelpMessage = "The applicationGateway")]
        public PSApplicationGateway ApplicationGateway { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            var sslCertificate = this.ApplicationGateway.SslCertificates.SingleOrDefault(resource => string.Equals(resource.Name, this.Name, System.StringComparison.CurrentCultureIgnoreCase));

            if (sslCertificate != null)
            {
                throw new ArgumentException("Ssl certificate with the specified name already exists");
            }            

            sslCertificate = base.NewObject();            
            this.ApplicationGateway.SslCertificates.Add(sslCertificate);

            WriteObject(this.ApplicationGateway);
        }
    }
}