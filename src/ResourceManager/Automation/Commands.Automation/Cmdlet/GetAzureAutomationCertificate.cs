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
using System.Collections.Generic;
using System.Management.Automation;
using System.Security.Permissions;
using Microsoft.Azure.Commands.Automation.Model;
using Microsoft.Azure.Commands.Automation.Common;

namespace Microsoft.Azure.Commands.Automation.Cmdlet
{
    /// <summary>
    /// Gets a certificate for automation.
    /// </summary>
    [Cmdlet(VerbsCommon.Get, "AzureRMAutomationCertificate", DefaultParameterSetName = AutomationCmdletParameterSets.ByAll)]
    [OutputType(typeof(CertificateInfo))]
    public class GetAzureAutomationCertificate : AzureAutomationBaseCmdlet
    {
        /// <summary>
        /// Gets or sets the certificate name.
        /// </summary>
        [Parameter(ParameterSetName = AutomationCmdletParameterSets.ByCertificateName, Position = 2, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The certificate name.")]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        /// <summary>
        /// Execute this cmdlet.
        /// </summary>
        [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
        protected override void AutomationProcessRecord()
        {
            IEnumerable<CertificateInfo> ret = null;
            if (this.ParameterSetName == AutomationCmdletParameterSets.ByCertificateName)
            {
                ret = new List<CertificateInfo> 
                { 
                   this.AutomationClient.GetCertificate(this.ResourceGroupName, this.AutomationAccountName, this.Name)
                };
                this.GenerateCmdletOutput(ret);
            }
            else 
            {
                var nextLink = string.Empty;

                do
                {
                    ret = this.AutomationClient.ListCertificates(this.ResourceGroupName, this.AutomationAccountName, ref nextLink);
                    this.GenerateCmdletOutput(ret);

                } while (!string.IsNullOrEmpty(nextLink));
            }
        }
    }
}
