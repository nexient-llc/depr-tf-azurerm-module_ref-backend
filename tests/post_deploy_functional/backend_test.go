// Copyright 2022 Nexient LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package test

// Basic imports
import (
	"fmt"
	"os"
	"path"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/suite"
)

// Define the suite, and absorb the built-in basic suite
// functionality from testify - including a T() method which
// returns the current testing context
type TerraTestSuite struct {
	suite.Suite
	TerraformOptions *terraform.Options
	suiteSetupDone   bool
}

// setup to do before any test runs
func (suite *TerraTestSuite) SetupSuite() {
	// Ensure that the destroy method is called even if the apply fails
	defer func() {
		if !suite.suiteSetupDone {
			terraform.Destroy(suite.T(), suite.TerraformOptions)
		}
	}()
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(suite.T(), "../..", ".")
	_ = files.CopyFile(path.Join("..", "..", ".tool-versions"), path.Join(tempTestFolder, ".tool-versions"))
	pwd, _ := os.Getwd()
	suite.TerraformOptions = terraform.WithDefaultRetryableErrors(suite.T(), &terraform.Options{
		TerraformDir: tempTestFolder,
		VarFiles:     [](string){path.Join(pwd, "..", "demo.tfvars")},
	})
	// unable to make the terraform idempotent for the User Identity (identity_ids)
	terraform.InitAndApply(suite.T(), suite.TerraformOptions)
	suite.suiteSetupDone = true
}

// TearDownAllSuite has a TearDownSuite method, which will run after all the tests in the suite have been run.
func (suite *TerraTestSuite) TearDownSuite() {
	terraform.Destroy(suite.T(), suite.TerraformOptions)
}

// In order for 'go test' to run this suite, we need to create
// a normal test function and pass our suite to suite.Run
func TestRunSuite(t *testing.T) {
	suite.Run(t, new(TerraTestSuite))
}

// All methods that begin with "Test" are run as tests within a suite.
func (suite *TerraTestSuite) TestFrontDoor() {

	actualFrontDoorName := terraform.Output(suite.T(), suite.TerraformOptions, "front_door_name")
	actualFrontDoorId := terraform.Output(suite.T(), suite.TerraformOptions, "front_door_id")
	expectedFrontDoorName := "demo-eus-dev-000-fd-002"
	expectedRgName := "demo-eus-dev-000-rg-002"
	// NOTE: "subscriptionID" is overridden by the environment variable "ARM_SUBSCRIPTION_ID". <>
	subscriptionID := ""
	suite.Equal(actualFrontDoorName, expectedFrontDoorName, "The names should match")
	suite.NotEmpty(actualFrontDoorId, "Web App ID cannot be empty")
	azure.FrontDoorExists(suite.T(), expectedFrontDoorName, expectedRgName, subscriptionID)
	actualFdEpMap := terraform.OutputMap(suite.T(), suite.TerraformOptions, "frontend_endpoints")
	for name, id := range actualFdEpMap {
		fmt.Println("Endpoint Name: ", name, "=> ", "Endpoint Id: ", id)
		azure.FrontDoorFrontendEndpointExists(suite.T(), name, expectedFrontDoorName, expectedRgName, subscriptionID)
	}
	frontDoor := azure.GetFrontDoor(suite.T(), expectedFrontDoorName, expectedRgName, subscriptionID)
	fmt.Println(*frontDoor.FrontdoorID)
}

func (suite *TerraTestSuite) TestStorageAccount() {
	subscriptionID := ""
	expectedRgNames := map[string]string{
		"eastus": "demo-eus-dev-000-rg-002",
		"westus": "demo-wus-dev-000-rg-002",
	}
	storageAccountNames := terraform.OutputMap(suite.T(), suite.TerraformOptions, "storage_account_names")
	for region, rg_name := range expectedRgNames {
		azure.StorageAccountExists(suite.T(), storageAccountNames[region], rg_name, subscriptionID)
	}
}

func (suite *TerraTestSuite) TestKeyVault() {
	actualKeyVaultIds := terraform.OutputMap(suite.T(), suite.TerraformOptions, "key_vault_ids")
	for _, key_vault_id := range actualKeyVaultIds {
		suite.NotEmpty(key_vault_id, "Key Vault ID should not be empty")
	}

}

func (suite *TerraTestSuite) TestResourceGroup() {
	// regions := [2]string{"eastus", "westus"}
	resourceGroupMap := terraform.OutputMap(suite.T(), suite.TerraformOptions, "resource_group_names")
	subscriptionID := ""
	for _, rg_name := range resourceGroupMap {
		azure.ResourceGroupExists(suite.T(), rg_name, subscriptionID)
	}

}

func (suite *TerraTestSuite) TestWebApp() {
	expectedWebAppNames := map[string]string{
		"eastus": "demo-eus-dev-000-app-002",
		"westus": "demo-wus-dev-000-app-002",
	}

	expectedRgNames := map[string]string{
		"eastus": "demo-eus-dev-000-rg-002",
		"westus": "demo-wus-dev-000-rg-002",
	}
	actualWebAppNames := terraform.OutputMap(suite.T(), suite.TerraformOptions, "web_app_names")
	actualWebAppIds := terraform.OutputMap(suite.T(), suite.TerraformOptions, "web_app_ids")

	// NOTE: "subscriptionID" is overridden by the environment variable "ARM_SUBSCRIPTION_ID". <>
	subscriptionID := ""
	for region, webAppName := range actualWebAppNames {
		suite.Equal(webAppName, expectedWebAppNames[region], "The names should match")
	}

	for _, webAppId := range actualWebAppIds {
		suite.NotEmpty(webAppId, "Web App ID cannot be empty")
	}
	for region, webAppName := range expectedWebAppNames {
		azure.AppExists(suite.T(), webAppName, expectedRgNames[region], subscriptionID)
	}
}
