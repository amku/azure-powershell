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

using Microsoft.Azure.Commands.ActiveDirectory.Models;
using Microsoft.Azure.Commands.Resources.Models.ActiveDirectory;
using System.Collections.Generic;
using System.Management.Automation;
using System;
using ProjectResources = Microsoft.Azure.Commands.Resources.Properties.Resources;

namespace Microsoft.Azure.Commands.ActiveDirectory
{
    /// <summary>
    /// Removes the AD application.
    /// </summary>
    [Cmdlet(VerbsCommon.Remove, "AzureRMADApplication")]
    public class RemoveAzureADApplicationCommand : ActiveDirectoryBaseCmdlet
    {
        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, HelpMessage = "The application object id.")]
        public Guid ApplicationObjectId { get; set; }

        [Parameter(Mandatory = false)]
        public SwitchParameter Force { get; set; }

        protected override void ProcessRecord()
        {
            ConfirmAction(
               Force.IsPresent,
               string.Format(ProjectResources.RemovingApplication, ApplicationObjectId.ToString()),
               ProjectResources.RemoveApplication,
               ApplicationObjectId.ToString(),
               () => ActiveDirectoryClient.RemoveApplication(ApplicationObjectId.ToString()));
        }
    }
}