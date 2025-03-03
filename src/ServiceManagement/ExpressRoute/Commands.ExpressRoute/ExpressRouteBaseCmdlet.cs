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

using Microsoft.WindowsAzure.Commands.Utilities.Common;

namespace Microsoft.WindowsAzure.Commands.ExpressRoute
{
    public abstract class ExpressRouteBaseCmdlet : AzureSMCmdlet
    {
        private ExpressRouteClient expressRouteClient;

        public ExpressRouteClient ExpressRouteClient
        {
            get
            {
                if (expressRouteClient == null)
                {
                    expressRouteClient = new ExpressRouteClient(Profile, Profile.DefaultContext.Subscription);
                }
                return expressRouteClient;
            }

            set { expressRouteClient = value; }
        }
    }
}
