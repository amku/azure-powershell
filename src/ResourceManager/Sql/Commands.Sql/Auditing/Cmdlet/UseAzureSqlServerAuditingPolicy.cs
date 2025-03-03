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

using Microsoft.Azure.Commands.Sql.Properties;
using Microsoft.Azure.Commands.Sql.Auditing.Model;
using System;
using System.Management.Automation;

namespace Microsoft.Azure.Commands.Sql.Auditing.Cmdlet
{
    /// <summary>
    /// Marks the given database as using its server's default policy instead of its own policy.
    /// </summary>
    [Cmdlet(VerbsOther.Use, "AzureRMSqlServerAuditingPolicy"), OutputType(typeof(DatabaseAuditingPolicyModel))]
    [Alias("Use-AzureSqlDatabaseServerAuditingPolicy")]
    public class UseAzureSqlServerAuditingPolicy : SqlDatabaseAuditingCmdletBase
    {
        /// <summary>
        ///  Defines whether the cmdlets will output the model object at the end of its execution
        /// </summary>
        [Parameter(Mandatory = false)]
        public SwitchParameter PassThru { get; set; }

        /// <summary>
        /// Returns true if the model object that was constructed by this cmdlet should be written out
        /// </summary>
        /// <returns>True if the model object should be written out, False otherwise</returns>
        protected override bool WriteResult() { return PassThru; }

        /// <summary>
        /// Updates the given model element with the cmdlet specific operation 
        /// </summary>
        /// <param name="model">A model object</param>
        protected override DatabaseAuditingPolicyModel ApplyUserInputToModel(DatabaseAuditingPolicyModel model)
        {
            base.ApplyUserInputToModel(model);
            model.UseServerDefault = UseServerDefaultOptions.Enabled;
            model.StorageAccountName = GetStorageAccountName();
            return model;
        }

        /// <summary>
        /// Returns the storage account name that is used at the policy of the database's server.
        /// </summary>
        /// <returns>A storage account name</returns>
        protected string GetStorageAccountName()
        {
            string storageAccountName = ModelAdapter.GetServerStorageAccount(ResourceGroupName, ServerName, clientRequestId);
            if (string.IsNullOrEmpty(storageAccountName))
            {
                throw new Exception(string.Format(Microsoft.Azure.Commands.Sql.Properties.Resources.UseServerWithoutStorageAccount));
            }
            return storageAccountName;
        }
    }
}
