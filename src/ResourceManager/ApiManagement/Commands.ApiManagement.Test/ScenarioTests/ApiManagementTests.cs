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

namespace Microsoft.Azure.Commands.ApiManagement.Test.ScenarioTests
{
    using System;
    using Microsoft.Azure.Common.Authentication;
    using Microsoft.Azure.Gallery;
    using Microsoft.Azure.Management.Authorization;
    using Microsoft.Azure.Management.Resources;
    using Microsoft.Azure.Test;
    using Microsoft.Azure.Test.HttpRecorder;
    using Microsoft.WindowsAzure.Commands.ScenarioTest;
    using WindowsAzure.Commands.Test.Utilities.Common;
    using Microsoft.WindowsAzure.Management;
    using Microsoft.WindowsAzure.Management.Storage;
    using Xunit;

    public class ApiManagementTests : RMTestBase
    {
        private readonly EnvironmentSetupHelper _helper;

        public ApiManagementTests()
        {
            _helper = new EnvironmentSetupHelper();
        }

        protected void SetupManagementClients()
        {
            var apiManagementManagementClient = GetApiManagementManagementClient();
            var resourceManagementClient = GetResourceManagementClient();
            var galaryClient = GetGalleryClient();
            var authorizationManagementClient = GetAuthorizationManagementClient();
            var managementClient = GetManagementClient();
            var storageManagementClient = GetStorageManagementClient();
            var armStorageManagementClient = GetArmStorageManagementClient();

            _helper.SetupManagementClients(
                apiManagementManagementClient, 
                resourceManagementClient,
                galaryClient,
                authorizationManagementClient,
                managementClient,
                armStorageManagementClient);
        }

        protected StorageManagementClient GetStorageManagementClient()
        {
            return TestBase.GetServiceClient<StorageManagementClient>(new RDFETestEnvironmentFactory());
        }

        protected Management.Storage.StorageManagementClient GetArmStorageManagementClient()
        {
            return TestBase.GetServiceClient<Management.Storage.StorageManagementClient>(new CSMTestEnvironmentFactory());
        }

        private ManagementClient GetManagementClient()
        {
            return TestBase.GetServiceClient<ManagementClient>(new RDFETestEnvironmentFactory());
        }

        private AuthorizationManagementClient GetAuthorizationManagementClient()
        {
            return TestBase.GetServiceClient<AuthorizationManagementClient>(new CSMTestEnvironmentFactory());
        }

        private GalleryClient GetGalleryClient()
        {
            return TestBase.GetServiceClient<GalleryClient>(new CSMTestEnvironmentFactory());
        }

        private ResourceManagementClient GetResourceManagementClient()
        {
            return TestBase.GetServiceClient<ResourceManagementClient>(new CSMTestEnvironmentFactory());
        }

        private Management.ApiManagement.ApiManagementClient GetApiManagementManagementClient()
        {
            return TestBase.GetServiceClient<Management.ApiManagement.ApiManagementClient>(new CSMTestEnvironmentFactory());
        }


        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestCrudApiManagement()
        {
            RunPowerShellTest("Test-CrudApiManagement");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestBackupRestoreApiManagement()
        {
            RunPowerShellTest("Test-BackupRestoreApiManagement");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestUpdateApiManagementDeployment()
        {
            RunPowerShellTest("Test-UpdateApiManagementDeployment");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestUpdateDeploymentComplex()
        {
            RunPowerShellTest("Test-UpdateApiManagementDeploymentWithHelpersAndPipline");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestImportApiManagementHostnameCertificate()
        {
            RunPowerShellTest("Test-ImportApiManagementHostnameCertificate");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestSetApiManagementVirtualNetworks()
        {
            RunPowerShellTest("Test-SetApiManagementVirtualNetworks");
        }

        private void RunPowerShellTest(params string[] scripts)
        {
#if DEBUG
            //Environment.SetEnvironmentVariable("AZURE_TEST_MODE", "Record");

            //Environment.SetEnvironmentVariable(
            //    "TEST_CSM_ORGID_AUTHENTICATION",
            //    "SubscriptionId=;Environment=;AADTenant=");

            //Environment.SetEnvironmentVariable(
            //    "TEST_ORGID_AUTHENTICATION",
            //    "SubscriptionId=;Environment=");
#endif

            using (var context = UndoContext.Current)
            {
                context.Start(TestUtilities.GetCallingClass(), TestUtilities.GetCurrentMethodName(2));

                SetupManagementClients();

                _helper.SetupEnvironment(AzureModule.AzureResourceManager);
                _helper.SetupModules(AzureModule.AzureResourceManager, "ScenarioTests\\Common.ps1", "ScenarioTests\\" + GetType().Name + ".ps1");

                _helper.RunPowerShellTest(scripts);
            }
        }
    }
}