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
using System.Web;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.Management.BackupServices.Models;
using MBS = Microsoft.Azure.Management.BackupServices;
using Microsoft.Azure.Commands.AzureBackup.Properties;
using Microsoft.Azure.Commands.AzureBackup.Models;
using Microsoft.Azure.Commands.AzureBackup.Helpers;
using Microsoft.Azure.Management.BackupServices;

namespace Microsoft.Azure.Commands.AzureBackup.Cmdlets
{
    /// <summary>
    /// Enables reregistration of a machine container
    /// </summary>
    [Cmdlet(VerbsLifecycle.Enable, "AzureRMBackupContainerReregistration")]
    public class EnableAzureRMBackupContainerReregistration : AzureBackupContainerCmdletBase
    {
        protected override void ProcessRecord()
        {
            ExecutionBlock(() =>
            {
                base.ProcessRecord();

                AzureBackupContainerType containerType = (AzureBackupContainerType)Enum.Parse(typeof(AzureBackupContainerType), Container.ContainerType);
                switch (containerType)
                {
                    case AzureBackupContainerType.Windows:
                    case AzureBackupContainerType.SCDPM:
                        AzureBackupClient.EnableMachineContainerReregistration(Container.ResourceGroupName, Container.ResourceName, Container.Id);
                        break;
                    default:
                        throw new ArgumentException(Resources.CannotEnableRegistration);
                }
            });
        }
    }
}
