# Using Azure API Management to publish services

This Terraform configuration sets up an example Function App exposing a REST API which performs its own Azure Entra-based OAuth2 authentication and authorization and implements [Azure API Management scenario #1](https://learn.microsoft.com/en-us/azure/api-management/authentication-authorization-overview) which has API Management perform additional JWT validation. Note that this configuration only supports OAuth 2.0 code flow for the example Function App. Put differently, it assumes that all requests to the REST API include authorization headers with valid JWT tokens. The caller is responsible for obtaining an access token (see testing below).

A real-world setup would have the Azure Function App on a private subnet, but this requires an expensive service plan and additional configuration on the API Management instance. The purpose of this example is to demonstrate authn/authz with Azure API Management, so we keep it simple and use a public Function App, which anyway authenticates separately.

Deploy the configuration with:

```shell
terraform init
terraform plan -out ze-plan
terraform apply ze-plan
```

Then switch to the example Function App and deploy the code. This step requires [Node.js](https://nodejs.org/en/download/current) c:a v18, npm and [azure-functions-core-tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) to be installed.

```shell
cd ../example-func-app
func azure functionapp publish bittrance-test-hello
```

Create a service principal with which access can be tested:

```shell
az ad app create --display-name api-access-test
TEST_APP_ID=$(az ad app list --display-name api-access-test --query '[0].appId' --output tsv)
API_APP_ID=$(az ad app list --display-name bittrance-test-hello --query '[0].appId' --output tsv)
API_ROLE_ID=$(az ad app list --display-name bittrance-test-hello --query '[].appRoles[0].id' --output tsv)
az ad sp create --id $TEST_APP_ID
PASSWORD=$(az ad sp credential reset --id $TEST_APP_ID --query password --output tsv)
az ad app permission add --id $TEST_APP_ID --api $API_APP_ID --api-permissions $API_ROLE_ID=Role
az ad app permission admin-consent --id $TEST_APP_ID
```

At this point, you should be able to request an access token for interacting with the API. Note that we request access for this specific API.

```shell
TENANT_ID=$(az account show --query tenantId --output tsv)
ACCESS_TOKEN=$( \
    curl --fail-with-body --no-progress-meter \
    -d scope=api://bittrance-test-hello/.default \
    -d grant_type=client_credentials \
    -d ad_tenant_id=$TENANT_ID \
    -d client_id=$TEST_APP_ID \
    -d "client_secret=$PASSWORD" \
    https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token | jq -r .access_token \
)
```

Using the access token, we can now call the API:

```shell
curl --fail-with-body --no-progress-meter \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    https://bittrance-test.azure-api.net/api/hello
```
