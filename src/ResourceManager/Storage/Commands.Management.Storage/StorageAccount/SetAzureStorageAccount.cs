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

using Microsoft.Azure.Commands.Resources.Models;
using Microsoft.Azure.Commands.Tags.Model;
using Microsoft.Azure.Management.Storage;
using Microsoft.Azure.Management.Storage.Models;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;

namespace Microsoft.Azure.Commands.Management.Storage
{
    /// <summary>
    /// Lists all storage services underneath the subscription.
    /// </summary>
    [Cmdlet(VerbsCommon.Set, StorageAccountNounStr, DefaultParameterSetName = UpdateAccountTypeParamSet), OutputType(typeof(StorageAccount))]
    public class SetAzureStorageAccountCommand : StorageAccountBaseCmdlet
    {
        protected const string UpdateAccountTypeParamSet = "UpdateAccountType";
        protected const string UpdateCustomDomainParamSet = "UpdateCustomDomain";
        protected const string UpdateTagsParamSet = "UpdateTags";

        [Parameter(
            Position = 0,
            Mandatory = true,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Resource Group Name.")]
        [ValidateNotNullOrEmpty]
        public string ResourceGroupName { get; set; }

        [Parameter(
            Position = 1,
            Mandatory = true,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Storage Account Name.")]
        [Alias(StorageAccountNameAlias, AccountNameAlias)]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        [Parameter(
            Position = 2,
            Mandatory = true,
            ParameterSetName = UpdateAccountTypeParamSet,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Storage Account Type.")]
        [ValidateSet(AccountTypeString.StandardLRS,
            AccountTypeString.StandardZRS,
            AccountTypeString.StandardGRS,
            AccountTypeString.StandardRAGRS,
            AccountTypeString.PremiumLRS,
            IgnoreCase = true)]
        public string Type { get; set; }

        [Parameter(
            Position = 2,
            Mandatory = true,
            ParameterSetName = UpdateCustomDomainParamSet,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Storage Account Custom Domain Name.")]
        [ValidateNotNullOrEmpty]
        public string CustomDomainName { get; set; }

        [Parameter(
            Position = 3,
            ParameterSetName = UpdateCustomDomainParamSet,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "To Use Sub Domain Name.")]
        [ValidateNotNullOrEmpty]
        public bool? UseSubDomain { get; set; }

        [Parameter(
            Position = 2,
            Mandatory = true,
            ParameterSetName = UpdateTagsParamSet,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Storage Account Tags.")]
        [ValidateNotNullOrEmpty]
        public Hashtable[] Tags { get; set; }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();

            Dictionary<string, string> tagDictionary = null;
            StorageAccountUpdateParameters updateParameters = null;

            if (ParameterSetName == UpdateAccountTypeParamSet)
            {
                updateParameters = new StorageAccountUpdateParameters
                    {
                        AccountType = ParseAccountType(this.Type)
                    };
            }
            else if (ParameterSetName == UpdateCustomDomainParamSet)
            {
                updateParameters = new StorageAccountUpdateParameters
                    {
                        CustomDomain = new CustomDomain
                        {
                            Name = CustomDomainName,
                            UseSubDomain = UseSubDomain
                        }
                    };
            }
            else
            {
                tagDictionary = TagsConversionHelper.CreateTagDictionary(Tags, validate: true);

                updateParameters = new StorageAccountUpdateParameters
                    {
                        Tags = tagDictionary
                    };
            }

            var updatedAccountResponse = this.StorageClient.StorageAccounts.Update(
                this.ResourceGroupName,
                this.Name,
                updateParameters);

            var accountProperties = this.StorageClient.StorageAccounts.GetProperties(this.ResourceGroupName, this.Name);

            WriteStorageAccount(accountProperties.StorageAccount);
        }
    }
}
