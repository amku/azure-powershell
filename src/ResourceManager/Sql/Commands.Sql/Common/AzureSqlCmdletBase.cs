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

using System.Management.Automation;
using Microsoft.Azure.Commands.ResourceManager.Common;
using Microsoft.Azure.Commands.Sql.Services;
using Microsoft.Azure.Common.Authentication.Models;
using Microsoft.WindowsAzure.Commands.Utilities.Common;

namespace Microsoft.Azure.Commands.Sql.Common
{
    /// <summary>
    /// The base class for all Azure Sql cmdlets
    /// </summary>
    public abstract class AzureSqlCmdletBase<M, A> : AzureRMCmdlet
    {
        /// <summary>
        /// Stores the per request session Id for all request made in this cmdlet call.
        /// </summary>
        protected string clientRequestId { get; set; }

        /// <summary>
        /// Default constructor.  Generates a request ID
        /// </summary>
        internal AzureSqlCmdletBase()
        {
            this.clientRequestId = Util.GenerateTracingId();
        }

        /// <summary>
        /// Gets or sets the name of the resource group to use.
        /// </summary>
        [Parameter(Mandatory = true, 
            ValueFromPipelineByPropertyName = true, 
            Position = 0,
            HelpMessage = "The name of the resource group")]
        [ValidateNotNullOrEmpty]
        public string ResourceGroupName { get; set; }

        /// <summary>
        /// The ModelAdapter object used by this cmdlet
        /// </summary>
        public A ModelAdapter { get; internal set; }

        /// <summary>
        /// Gets an entity from the service
        /// </summary>
        /// <returns>A model object</returns>
        protected abstract M GetEntity();

        /// <summary>
        /// Updates the given model element with the cmdlet specific operation 
        /// </summary>
        /// <param name="model">A model object</param>
        protected virtual M ApplyUserInputToModel(M model) { return model; }

        /// <summary>
        /// This method is responsible to call the right API in the communication layer that will eventually send the information in the 
        /// object to the REST endpoint
        /// </summary>
        /// <param name="entity">The model object with the data to be sent to the REST endpoints</param>
        protected virtual M PersistChanges(M entity) { return default(M); }

        /// <summary>
        /// Returns true if the model object that was constructed by this cmdlet should be written out
        /// </summary>
        /// <returns>True if the model object should be written out, False otherwise</returns>
        protected virtual bool WriteResult() { return true; }

        /// <summary>
        /// Creation and initialization of the ModelAdapter object
        /// </summary>
        /// <param name="subscription">The AzureSubscription in which the current execution is performed</param>
        /// <returns>An initialized and ready to use ModelAdapter object</returns>
        protected abstract A InitModelAdapter(AzureSubscription subscription);

        /// <summary>
        /// Executes the cmdlet
        /// </summary>
        protected override void ProcessRecord()
        {
            ModelAdapter = InitModelAdapter(DefaultProfile.DefaultContext.Subscription);
            M model = this.GetEntity();
            M updatedModel = this.ApplyUserInputToModel(model);
            M responseModel = this.PersistChanges(updatedModel);

            if(responseModel != null)
            {
                if (WriteResult())
                {
                    this.WriteObject(responseModel, true);
                }
            }
            else
            {
                if (WriteResult())
                {
                    this.WriteObject(updatedModel);
                }
            }
        }
    }
}