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

using Microsoft.Azure.Commands.Sql.Auditing.Model;
using System.Management.Automation;

namespace Microsoft.Azure.Commands.Sql.Auditing.Cmdlet
{
    /// <summary>
    /// Disables auditing on a specific database server.
    /// </summary>
    [Cmdlet(VerbsCommon.Remove, "AzureRMSqlServerAuditing"), OutputType(typeof(ServerAuditingPolicyModel))]
    [Alias("Remove-AzureSqlDatabaseServerAuditing")]
    public class RemoveSqlServerAuditing : SqlDatabaseServerAuditingCmdletBase
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
        protected override ServerAuditingPolicyModel ApplyUserInputToModel(ServerAuditingPolicyModel model)
        {
            base.ApplyUserInputToModel(model);
            model.AuditState = AuditStateType.Disabled;
            return model;
        }

        /// <summary>
        /// This method is responsible to call the right API in the communication layer that will eventually send the information in the 
        /// object to the REST endpoint
        /// </summary>
        /// <param name="model">The model object with the data to be sent to the REST endpoints</param>
        protected override ServerAuditingPolicyModel PersistChanges(ServerAuditingPolicyModel model)
        {
            ModelAdapter.IgnoreStorage = true;
            base.PersistChanges(model);
            return null;
        }
    }
}