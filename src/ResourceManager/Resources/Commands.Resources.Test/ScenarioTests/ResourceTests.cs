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


using Microsoft.WindowsAzure.Commands.ScenarioTest;
using Microsoft.WindowsAzure.Commands.Test.Utilities.Common;
using Xunit;

namespace Microsoft.Azure.Commands.Resources.Test.ScenarioTests
{
    public class ResourceTests : RMTestBase
    {
        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestCreatesNewSimpleResource()
        {
            ResourcesController.NewInstance.RunPsTest("Test-CreatesNewSimpleResource");
        }

        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestCreatesNewComplexResource()
        {
            ResourcesController.NewInstance.RunPsTest("Test-CreatesNewComplexResource");
        }

        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGetResourcesViaPiping()
        {
            ResourcesController.NewInstance.RunPsTest("Test-GetResourcesViaPiping");
        }

        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGetResourcesFromEmptyGroup()
        {
            ResourcesController.NewInstance.RunPsTest("Test-GetResourcesFromEmptyGroup");
        }

        [Fact (Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGetResourcesFromNonExisingGroup()
        {
            ResourcesController.NewInstance.RunPsTest("Test-GetResourcesFromNonExisingGroup");
        }

        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGetResourcesForNonExisingType()
        {
            ResourcesController.NewInstance.RunPsTest("Test-GetResourcesForNonExisingType");
        }

        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGetResourceForNonExisingResource()
        {
            ResourcesController.NewInstance.RunPsTest("Test-GetResourceForNonExisingResource");
        }

        [Fact(Skip = "TODO: Re-record")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGetResourcesViaPipingFromAnotherResource()
        {
            ResourcesController.NewInstance.RunPsTest("Test-GetResourcesViaPipingFromAnotherResource");
        }

        [Fact]
        public void TestMoveAResourceTest()
        {
            ResourcesController.NewInstance.RunPsTest("Test-MoveAResource");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestSetAResourceTest()
        {
            ResourcesController.NewInstance.RunPsTest("Test-SetAResource");
        }
    }
}
