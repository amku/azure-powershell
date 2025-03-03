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

using System.Collections;
using System.Management.Automation;
using System.Security.Permissions;
using Microsoft.Azure.Commands.Automation.Common;
using Microsoft.Azure.Commands.Automation.Model;
using Microsoft.WindowsAzure.Commands.Utilities.Common;

namespace Microsoft.Azure.Commands.Automation.Cmdlet
{
    /// <summary>
    /// Sets an azure automation runbook definition.
    /// </summary>
    [Cmdlet(VerbsData.Import, "AzureRMAutomationRunbook")]
    [OutputType(typeof(Runbook))]
    public class ImportAzureAutomationRunbook : AzureAutomationBaseCmdlet
    {
        
        /// <summary>
        /// Gets or sets the path of the runbook script
        /// </summary>
        [Parameter(Position = 2, Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The runbook file path.")]
        [Alias("SourcePath")]
        [ValidateNotNullOrEmpty]
        public string Path { get; set; }

        /// <summary>
        /// Gets or sets the runbook description
        /// </summary>
        [Parameter(Mandatory = false, ValueFromPipelineByPropertyName = true, HelpMessage = "The runbook description.")]
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets the runbook tags.
        /// </summary>
        [Parameter(Mandatory = false, ValueFromPipelineByPropertyName = true, HelpMessage = "The runbook tags.")]
        [Alias("Tag")]
        public IDictionary Tags { get; set; }

        /// <summary>
        /// Gets or sets the runbook version type
        /// </summary>
        [Parameter(Mandatory = true, HelpMessage = "Runbook definition type.")]
        [ValidateSet(Constants.RunbookType.Graph, Constants.RunbookType.PowerShell, Constants.RunbookType.PowerShellWorkflow, IgnoreCase = true)]
        [ValidateNotNullOrEmpty]
        public string Type { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether progress logging should be turned on or off.
        /// </summary>
        [Parameter(Mandatory = false, ValueFromPipelineByPropertyName = true, HelpMessage = "Indicate whether progress logging should be turned on or off.")]
        public bool? LogProgress { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether verbose logging should be turned on or off.
        /// </summary>
        [Parameter(Mandatory = false, ValueFromPipelineByPropertyName = true, HelpMessage = "Indicate whether verbose logging should be turned on or off.")]
        public bool? LogVerbose { get; set; }

        /// <summary>
        /// Gets or sets the switch parameter to publish the configuration
        /// </summary>
        [Parameter(Mandatory = false, HelpMessage = "Import the runbook in published state.")]
        public SwitchParameter Published { get; set; }
        
        /// <summary>
        /// Gets or sets switch parameter to confirm overwriting of existing runbook definition.
        /// </summary>
        [Parameter(Mandatory = false, HelpMessage = "Forces the command to overwrite an existing runbook definition.")]
        public SwitchParameter Force { get; set; }
       
        /// <summary>
        /// Execute this cmdlet.
        /// </summary>
        [PermissionSet(SecurityAction.Demand, Name = "FullTrust")]
        protected override void AutomationProcessRecord()
        {
            var runbook = this.AutomationClient.ImportRunbook(
                    this.ResourceGroupName, 
                    this.AutomationAccountName, 
                    this.ResolvePath(this.Path),
                    this.Description,
                    this.Tags, 
                    this.Type, 
                    this.LogProgress, 
                    this.LogVerbose,
                    this.Published.IsPresent,
                    this.Force.IsPresent);

            this.WriteObject(runbook);
        }
    }
}
