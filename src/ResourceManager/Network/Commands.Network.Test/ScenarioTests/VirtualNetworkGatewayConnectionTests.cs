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
using Xunit;

namespace Commands.Network.Test.ScenarioTests
{
    public class VirtualNetworkGatewayConnectionTests : Microsoft.WindowsAzure.Commands.Test.Utilities.Common.RMTestBase
    {
        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestVirtualNetworkGatewayConnectionCRUD()
        {
            NetworkResourcesController.NewInstance.RunPsTest("Test-VirtualNetworkGatewayConnectionCRUD");
        }

        [Fact(Skip = "TODO: Will send another PR after re-recording test")]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestVirtualNetworkGatewayConnectionSharedKeyCRUD()
        {
            NetworkResourcesController.NewInstance.RunPsTest("Test-VirtualNetworkGatewayConnectionSharedKeyCRUD");
        }
    }
}
