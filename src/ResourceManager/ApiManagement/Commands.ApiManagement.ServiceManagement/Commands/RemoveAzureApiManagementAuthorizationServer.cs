﻿//  
// Copyright (c) Microsoft.  All rights reserved.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

namespace Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Commands
{
    using System;
    using System.Globalization;
    using System.Management.Automation;
    using Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models;
    using Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Properties;

    [Cmdlet(VerbsCommon.Remove, "AzureRMApiManagementAuthorizationServer")]
    [OutputType(typeof(bool))]
    public class RemoveAzureApiManagementAuthorizationServer : AzureApiManagementRemoveCmdletBase
    {
        [Parameter(ValueFromPipelineByPropertyName = true, Mandatory = true, HelpMessage = "Instance of PsApiManagementContext. This parameter is required.")]
        [ValidateNotNullOrEmpty]
        public PsApiManagementContext Context { get; set; }

        [Parameter(ValueFromPipelineByPropertyName = true, Mandatory = true, HelpMessage = "Identifier of existing authorization server. This parameter is required.")]
        [ValidateNotNullOrEmpty]
        public String ServerId { get; set; }

        public override string ActionWarning
        {
            get { return string.Format(CultureInfo.CurrentCulture, Resources.GroupRemoveWarning, ServerId); }
        }

        public override string ActionDescription
        {
            get { return string.Format(CultureInfo.CurrentCulture, Resources.GroupRemoveDescription, ServerId); }
        }
      
        protected override void ExecuteRemoveLogic()
        {
            Client.AuthorizationServerRemove(Context, ServerId);
        }
    }
}
