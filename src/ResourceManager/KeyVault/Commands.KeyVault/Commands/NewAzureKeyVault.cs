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
using System.Collections;
using System.Management.Automation;
using Microsoft.Azure.Management.KeyVault;
using PSKeyVaultModels = Microsoft.Azure.Commands.KeyVault.Models;
using PSKeyVaultProperties = Microsoft.Azure.Commands.KeyVault.Properties;

namespace Microsoft.Azure.Commands.KeyVault
{
    /// <summary>
    /// Create a new key vault. 
    /// </summary>
    [Cmdlet(VerbsCommon.New, "AzureRMKeyVault", HelpUri = Constants.KeyVaultHelpUri)]
    [OutputType(typeof (PSKeyVaultModels.PSVault))]
    public class NewAzureKeyVault : KeyVaultManagementCmdletBase
    {
        #region Input Parameter Definitions

        /// <summary>
        /// Vault name
        /// </summary>
        [Parameter(Mandatory = true,
            Position = 0,
            ValueFromPipelineByPropertyName = true,
            HelpMessage =
                "Specifies a name of the key vault to create. The name can be any combination of letters, digits, or hyphens. The name must start and end with a letter or digit. The name must be universally unique."
            )]
        [ValidatePattern("^[a-zA-Z0-9-]{3,24}$")]
        [ValidateNotNullOrEmpty]
        public string VaultName { get; set; }

        /// <summary>
        /// Resource group name
        /// </summary>
        [Parameter(Mandatory = true,
            Position = 1,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Specifies the name of an existing resource group in which to create the key vault.")]
        [ValidateNotNullOrEmpty()]
        public string ResourceGroupName { get; set; }

        /// <summary>
        /// Location
        /// </summary>
        [Parameter(Mandatory = true,
            Position = 2,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Specifies the Azure region in which to create the key vault. Use the command Get-AzureLocation to see your choices. For more information, type Get-Help Get-AzureLocation.")]
        [ValidateNotNullOrEmpty()]
        public string Location { get; set; }

        [Parameter(Mandatory = false,            
            ValueFromPipelineByPropertyName = true,
            HelpMessage =
                "If specified, enables secrets to be retrieved from this key vault by the Microsoft.Compute resource provider when referenced in resource creation."
            )]
        public SwitchParameter EnabledForDeployment { get; set; }        

        [Parameter(Mandatory = false,            
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Specifies the SKU of the key vault instance. For information about which features are available for each SKU, see the Azure Key Vault Pricing website (http://go.microsoft.com/fwlink/?linkid=512521).")]
        [ValidateSet("standard", "premium")]
        public string Sku { get; set; }

        [Alias("Tags")]
        [Parameter(Mandatory = false,            
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "A hash table which represents resource tags.")]
        public Hashtable[] Tag { get; set; }

        #endregion

        protected override void ProcessRecord()
        {            
            if (VaultExistsInCurrentSubscription(this.VaultName))
            {
                throw new ArgumentException(PSKeyVaultProperties.Resources.VaultAlreadyExists);
            }

            var newVault = KeyVaultManagementClient.CreateNewVault(new PSKeyVaultModels.VaultCreationParameters()
            {
                VaultName = this.VaultName,
                ResourceGroupName = this.ResourceGroupName,
                Location = this.Location,
                EnabledForDeployment = this.EnabledForDeployment.IsPresent,
                SkuFamilyName = DefaultSkuFamily,
                SkuName = string.IsNullOrWhiteSpace(this.Sku) ? DefaultSkuName : this.Sku,
                TenantId = GetTenantId(),
                ObjectId = GetCurrentUsersObjectId(),
                PermissionsToKeys = DefaultPermissionsToKeys,
                PermissionsToSecrets = DefaultPermissionsToSecrets,
                Tags = this.Tag
            }, 
            ActiveDirectoryClient
            );
            
            this.WriteObject(newVault);
        }


    }
}
