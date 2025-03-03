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

namespace Microsoft.WindowsAzure.Commands.ServiceManagement.Network
{
    using Microsoft.Azure.Common.Authentication;
    using Microsoft.Azure.Common.Authentication.Models;
    using WindowsAzure.Commands.Common;
    using WindowsAzure.Commands.Utilities.Common;
    using WindowsAzure.Commands.Utilities.Profile;

    /// <summary>
    /// The base class for all Microsoft Azure Network Gateway Management Cmdlets
    /// </summary>
    public abstract class NetworkCmdletBase : AzureSMCmdlet
    {
        private NetworkClient client;

        protected AzureSubscription CurrentSubscription
        {
            get { return Profile.DefaultContext.Subscription; }
        }

        public NetworkClient Client
        {
            get
            {
                if (client == null)
                {
                    client = new NetworkClient(Profile, CurrentSubscription, CommandRuntime);
                }
                return client;
            }

            set { this.client = value; }
        }
    }
}