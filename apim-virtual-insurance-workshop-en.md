1# Workshop: Multi-Channel Virtual Insurance Advisor

**🌍 Language / Język:** [English](apim-virtual-insurance-workshop-en.md) EN | [Polski](apim-virtual-insurance-workshop-pl.md) PL

---

The goal of this workshop is to create an API interface for integration with a generative chatbot that can respond to customer questions about insurance policies, processing data in real-time and using Azure API Management to manage, monitor, and secure the API.

## Requirements for Participants

Before starting the workshop, make sure you have:

- An active Azure subscription (or free credits)
- Deployed Microsoft Foundry service with an available model, e.g., "gpt-4o-mini"
https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal
- Deployed "Azure Log Analytics" service
https://learn.microsoft.com/en-us/azure/api-management/monitor-api-management
- Deployed "Application Insights" service
https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest
- Installed tools:
    - Azure CLI (version 2.40.0 or higher)
    - Visual Studio Code or other IDE
    - Postman or other REST client (optional)
- Basic knowledge of REST API: HTTP requests, headers, response codes

---

## 1. CREATING THE FIRST API (POLICY KNOWLEDGE BASE)

### 1.1 Environment Preparation

1. Log in to Azure Portal (portal.azure.com)  
2. Verify that you have an active subscription

### 1.2 Creating Azure API Management Service

> 📋 **Cheat Sheet**: Check the document with data received from the organizers. You will find exact resource names and endpoints for your user number `{usernumber}`. If the Azure API Management resource has not been created for you, follow the steps below.

https://learn.microsoft.com/en-us/azure/api-management/get-started-create-service-instance

1. In Azure Portal, search for "API Management" in the search bar  
2. Click "+ Create"  
3. Fill out the form:
    - **Subscription**: select your subscription
    - **Resource Group**: create a new one (e.g., "rg-azureclubworkshopint-{usernumber}")
    - **Region**: select the closest one (e.g., France Central or Sweden Central)
    - **Name**: e.g., "apim-azureclubworkshopint-{usernumber}"
    - **Organization name**: your organization name
    - **Administrator email**: your email address
    - **Pricing tier**: Developer (cheapest, non-production option)
4. In the "Monitor + Secure" tab, check the "Log Analytics" and "Application Insights" options, select previously created resources.
5. In the "Virtual Network" tab, check the "Virtual Network" option, then select "External" from "Type". Via the "Create new" option, create a new virtual network, enter a name, and you can accept the default addressing. 
6. In the "Managed identity" tab, check the "Status" checkbox
7. Click "Review + create", then "Create"
8. Wait for the deployment to complete (may take 30-40 minutes)

### 1.3 Defining Data Model for Policies

https://learn.microsoft.com/en-us/azure/api-management/add-api-manually

For our API, we will use the following policy data model:

- ID (unique identifier)
- Policy type (e.g., health, auto, home)
- Available packages (e.g., premium, standard)
- Price (monthly)
- Description (what the policy covers)

### 1.4 Creating API for Policy Knowledge Base

1. Go to the created API Management resource
2. In the side menu, select "APIs", then select APIs again.
3. Click "+ Add API" and select "HTTP API"
4. Fill out the form:
    - **Display name**: PoliciesAPI
    - **Name**: policiesapi
    - **Web service URL**: you can temporarily enter "https://example.org"
    - **API URL suffix**: policies
5. Click "Create"

### 1.5 Adding GET /policies Operation

1. Select the created "PoliciesAPI" API
2. Click "+ Add operation"
3. Fill out the form:
    - **Display name**: GetPolicies
    - **Name**: getpolicies
    - **URL**: GET /policies
    - **Description**: Retrieves list of available policies
4. In the "Responses" section, click "+ Add response"
    - **Status code**: 200 OK
    - In "Representations" click "Add representation"  
    - In the "Content Type" field, select "application/json" (if application/json is not in the list, search for it at the beginning of the list or type "manually") 
    - In the "Sample" field, paste the sample schema: 

```json
[
  {
    "policyId": "123456",
    "policyType": "health",
    "package": "premium",
    "price": 100,
    "description": "Premium health insurance."
  },
  {
    "policyId": "123457",
    "policyType": "auto",
    "package": "standard",
    "price": 75,
    "description": "Basic car insurance."
  }
]
```

5. Click "Save"
6. Go to the "Settings" tab. In the "Subscription" section, uncheck the "Subscription required" option (for testing purposes)
7. Click "Save"
8. Select Design and go to "Inbound processing"
9. Click "Add policy", select "mock-response"
10. Click "Save"

### 1.6 Testing the API

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-api-inspector

1. Select the created API and go to the "Test" tab
2. Select the GET /policies operation
3. Click "Send"
4. In the "HTTP Response" section, verify that you receive a response with sample policy data 

---

## 2. EXPOSING OPEN AI THROUGH APIM

https://learn.microsoft.com/en-us/azure/api-management/azure-ai-foundry-api
https://learn.microsoft.com/en-us/azure/api-management/azure-openai-api-from-specification

### 2.1 Adding Azure OpenAI API

1. In the API Management resource, go to the "APIs" section
2. Click "+ Add API" and select "Azure AI Foundry"
3. In the "Select AI Service" tab, select the Microsoft Foundry service 
4. Click "Next"
3. Fill out the form:
    - **Display name**: policies-ai
    - **name**: policies-ai
    - **Base path**: policies-ai 
    - In the **Description** field, provide any description 
    - Check the "Azure OpenAI" option
4. Click "Next"
5. Check the "Track token usage" option (needed for billing) - familiarize yourself with the links https://learn.microsoft.com/en-us/azure/api-management/azure-openai-emit-token-metric-policy and https://learn.microsoft.com/en-us/azure/api-management/azure-openai-token-limit-policy

6. Select the available Application Insights instance as the place to store token metrics
7. In the "dimension" option, select: API ID, Subscription ID, Operation ID
8. Click "Next" - familiarize yourself with the "Semantic caching" option
https://learn.microsoft.com/en-us/azure/api-management/azure-openai-enable-semantic-caching
9. Click "Next" - familiarize yourself with the "AI content safety" option
https://learn.microsoft.com/en-us/azure/api-management/llm-content-safety-policy
10. Click "Next"
11. Click "Create"

Just configuring "Track token usage" is not enough for metrics to appear in "Application Insights". You still need to perform the configuration from the link below https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest such as "Create a connection between Application Insights and API Management", "Enable Application Insights logging for your API" as well as enabling "Emit custom metrics". For convenience, you can set the "metrics" option via cloudshell https://shell.azure.com

To log "LLM messages", i.e., "prompts" and "completions", follow the steps described in this document https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-llm-logs

```
az rest --method put \
  --url "https://management.azure.com/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupName}/providers/Microsoft.ApiManagement/service/{APIManagementServiceName}/diagnostics/applicationinsights?api-version=2025-03-01-preview" \
  --body '{
    "properties": {
      "loggerId": "/subscriptions/{SubscriptionId}/resourceGroups/{ResourceGroupName}/providers/Microsoft.ApiManagement/service/{APIManagementServiceName}/loggers/{ApplicationInsightsLoggerName}",
      "metrics": true
    }
  }'
```

You can view metrics in "Log Analytics" by entering the "customMetrics" query in "Search".

### 2.2 Testing OpenAI API Availability

1. After creating the API, select it from the list
2. Select the "Creates a completion for the chat message" operation
3. Go to the "Test" tab
4. For deployment, enter "gpt-4o-mini" (or another available model)
5. For api-version, enter "2024-05-01-preview"
6. In the body, place the following JSON:

```json
{
  "messages": [
    {
      "role": "system",
      "content": "Say Hello World"
    }
  ]
}
```

7. Click "Send" and check the response
8. This time, we did not disable the "Subscription required" option in the "Settings" tab, yet we were able to send a query. This happens because the portal automatically provides a key. You can verify this by sending a query with the "Trace" button.

### 2.3 Verifying Subscription Settings for policies-ai API

1. Go to "APIs" and select "policies-ai"
2. Go to the "Settings" tab
3. In the "Subscription" section, make sure the "Subscription required" option is checked
4. Make sure that the "Header name" value is "Ocp-Apim-Subscription-Key" and the "Query parameter name" shows "subscription-key"
5. Click "Save"

### 2.4 Adding Managed Identity Authentication to Microsoft Foundry

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-use-managed-service-identity

Check that "system managed identity" has been enabled for "API Management" and that permission has been granted for this identity to "Microsoft Foundry". "Managed Identity" should have been created during API Management creation, the role should have been assigned during the addition of the "policies-ai" API.

1. Go to your API Management
2. In the side menu, select "Managed identities"
3. Enable the "System assigned" option and click "Save"
4. Go to the Microsoft Foundry resource
5. Select "Access control (IAM)"
6. Click "+ Add" and select "Add role assignment"
7. Select the "Cognitive Services OpenAI User" role
8. In the "Members" tab, select "Managed identity" and point to your APIM
9. Click "Review + assign"

---

## 3. KEYS

### 3.1 Configuring API Keys in Azure API Management

https://learn.microsoft.com/en-us/azure/api-management/api-management-subscriptions

1. In the API Management resource, go to the "Subscriptions" section
2. Create a new subscription by clicking "+ Add":
    - **Name**: WorkshopSubscription
    - **Display name**: WorkshopSubscription
    - **Scope**: All APIs (or specific API)
3. After creation, click on the subscription and copy the generated key

### 3.2 Enabling Subscription Key Requirement for API

1. Go to "APIs" and select "PoliciesAPI"
2. Go to the "Settings" tab
3. In the "Subscription" section, check the "Subscription required" option
4. Make sure that the "Header name" value is "Ocp-Apim-Subscription-Key", and the "Query parameter name" shows "subscription-key"
5. Click "Save"

### 3.3 Testing API with Key

1. Go to the "Test" tab
2. Select the GET /policies operation
3. Click "Send" and verify that you receive a valid response
4. Check what the full request looks like (eye icon on the right side in the HTTP request section). The testing tool automatically adds the "Ocp-Apim-Subscription-Key" header. If you use other tools, remember to add the "Ocp-Apim-Subscription-Key" header with the correct key.

---

## 4. RATE LIMITS

### 4.1 Configuring Rate Limiting

https://learn.microsoft.com/en-us/azure/api-management/rate-limit-policy

1. Go to "APIs" and select "PoliciesAPI"
2. Select the "Designs" tab, stay in "All operations", go to the "Inbound processing" section, click on </>.
3. In the XML editor, in the `<inbound>` section, add after the `<base />` tag:

```xml
<rate-limit calls="5" renewal-period="30" />
```

4. Click "Save"

This policy limits the number of calls to 5 per 30 seconds.

### 4.2 Testing Call Limit

1. Go to the "Test" tab
2. Select the GET /policies operation
3. Click "Send" at least 6 times within 30 seconds
4. Note that after 5 calls, you receive a "429 Too Many Requests" error

### 4.3 Removing Rate Limiting

1. Return to the "Policies" tab
2. In the XML editor, remove the line

```xml
<rate-limit calls="5" renewal-period="30" />
```

3. Click "Save"

---

## 5. OAUTH 2.0

### 5.1 Registering Application in Microsoft Entra ID

**If you cannot register an application in Microsoft Entra ID (SPN), information regarding required access data, such as clientId, tenantId, and secret, will be provided to you.**

https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app

1. In Azure Portal, go to "Microsoft Entra ID"
2. Select "App registrations" and click "+ New registration"
3. Fill out the form:
    - **Name**: PoliciesAPI-OAuth-{usernumber} (enter your user number)
    - **Supported account types**: select "Accounts in this organizational directory only"
4. Click "Register"
5. Note the "Application (client) ID" and "Directory (tenant) ID" values
6. Go to "Manage" then "Certificates & secrets" 
7. Generate a secret and save the key (remember to save the key after generation – it will only be visible briefly). In the "Description" field, enter any value, in the "Expires" field, select "90 days"

### 5.2 Implementing Azure AD Authentication Policy

https://learn.microsoft.com/en-us/azure/api-management/validate-azure-ad-token-policy

1. Go to "Policies" for "PoliciesAPI"
2. In the XML editor, add in the `<inbound>` section after `<base />`:

```xml
        <validate-azure-ad-token tenant-id="xxxx">
            <client-application-ids>
                <application-id>xxxx</application-id>
            </client-application-ids>
        </validate-azure-ad-token>
```
3. Replace "xxxxxxxxxxx" with your Tenant ID and "xxxxxxxxxx" with your Client ID
4. Click "Save"

### 5.3 Create a Simple Azure Logic App to Help You Test Authentication

https://learn.microsoft.com/en-us/azure/logic-apps/quickstart-create-example-consumption-workflow

1. On the main page https://portal.azure.com, select "Create a resource".
2. Search for "Logic App", click "Create"
3. Select "Multi-tenant"
4. Select "Select"
5. Select the "Subscription" on which you deployed API Management
6. Select the "Resource Group" in which you deployed API Management
7. In the "Logic App name" field, enter "la-azureclubworkshopint-{usernumber}"
8. In the "Region" field, select the same region where you deployed API Management.
9. Click "Review + Create" then "Create".
10. After creating the resource, click "Go to resource".
11. Click "Edit"
12. Click "Add a trigger", select "Request", then "When a HTTP request is received", click "Save".
13. Click the + sign below the "When a HTTP request is received" tile, select "Add an action"
14. Search for "Azure API Management" - select "Choose an Azure API Management action", check your Azure API Management instance.
15. Select "PoliciesAPI", click "Add action".
16. In the "Operation Id" field, select "GetPolicies".
17. In the "Advanced parameters" field, check both "Authentication" and "Subscription key".
18. In the "Authentication" field, select Active Directory OAuth, then fill in all required fields such as "Tenant", "Audience", "Client ID", and "Secret". In the "Audience" field, enter "https://management.azure.com/".
19. In the "Subscription key" field, enter the key you generated in section "3.1", click "Save".
20. Click "Run" then "Run".
21. Go to "Overview" and check the result of sending the query to the "API" exposed by "Azure API Management" in the "Run History" tab.
22. You can experiment and change values, e.g., change the key to an incorrect one to verify that authentication works. You can check errors in "History".

---

## 6. OPEN AI TOKEN LIMIT

### 6.1 Configure "Azure Logic App" to Enable the Use of "Managed Identity" to Connect to Other Services, Such as "Azure API Management"

**If you do not have permissions to Microsoft Entra ID, use the Azure CLI command to display the application ID (Application ID). You can do this via Azure Cloud Shell.**

```bash
az ad sp show --id '[Object (principal) ID]' | ConvertFrom-Json | select displayName, appId
```

1. Go to "Azure Logic App" named "la-azureclubworkshopint-{usernumber}".
2. Go to the "Identity" tab, click "System assigned", select "ON", then "Save".
3. In Entra ID, find the "Application ID" for the "Managed Identity" created for "Azure Logic App". Go to "Entra ID", then "Enterprise applications". In "Application type", select "Managed Identity", search for the name "la-azureclubworkshopint-{usernumber}". Note the "Application ID".

### 6.2 Adding OpenAI Token Limit Policy

https://learn.microsoft.com/en-us/azure/api-management/azure-openai-token-limit-policy

1. Find "Azure API Management" in the Azure portal, then go to "APIs" and select the API for Microsoft Foundry named "policies-ai"
2. Go to the "Inbound processing" section, then "Policies", click on </>
3. In the XML editor, add in the `<inbound>` section after `<base />`:

```xml
<azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
```

**Note:** The following policy (points 4,5,6) is currently no longer required, API MGMT in the "Backend" tab automatically adds Managed Identity API MGMT to connect to Microsoft Foundry, however it is worth reviewing the policy as it may be useful in other integrations.

4. Also add Managed Identity authentication policy to Azure OpenAI:

https://learn.microsoft.com/en-us/azure/api-management/authentication-managed-identity-policy

```xml
<authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="managed-id-access-token" ignore-error="false" />
<set-header name="Authorization" exists-action="override">
  <value>@("Bearer " + (string)context.Variables["managed-id-access-token"])</value>
</set-header>
```

5. Check if the OpenAI backend is set:

Backend-id must have the same name as "Backend name" in the "Backends" tab.

```xml
<set-backend-service id="apim-generated-policy" backend-id="policies-ai-openai-endpoint" />
```

6. Click "Save"

https://learn.microsoft.com/en-us/azure/api-management/validate-azure-ad-token-policy

8. Change the "validate-azure-ad-token tenant-id" policy to authenticate communication only from a specific Managed Identity - in this case, connected under Azure Logic App. Provide the "application-id" from section 6.1.3.

```xml
    <validate-azure-ad-token tenant-id="xxxxxxxxxxx">
      <client-application-ids>
        <application-id>xxxxxxxxxx</application-id>
      </client-application-ids>
    </validate-azure-ad-token>
```

The complete policy should look like this:

```xml
<policies>
  <inbound>
    <base />
    <validate-azure-ad-token tenant-id="xxxxxxxxxxx">
      <client-application-ids>
        <application-id>xxxxxxxxxx</application-id>
      </client-application-ids>
    </validate-azure-ad-token>
    <azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
            <llm-emit-token-metric>
            <dimension name="User ID" />
            <dimension name="Subscription ID" />
            <dimension name="Operation ID" />
        </llm-emit-token-metric>
    <set-backend-service id="apim-generated-policy" backend-id="polisy-ai-openai-endpoint" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
```

### 6.3 Adding Another Connector to the Existing Azure Logic App That Will Enable Communication with Azure OpenAI

1. Go to Azure Logic App, then click "Edit".
2. Click on the first element "When a HTTP request is received". In the "Request Body JSON Schema" field, paste the following code

```
{
    "type": "object",
    "properties": {
        "prompt": {
            "type": "string"
        }
    }
}
```

3. Add an action named "API Management" at the very end of the flow (via the + sign). Fill out the form, select your API Management, then select policies-ai API, click "Add action".
4. In the "Operation Id" field, select "Creates a completion for the chat message".
5. In the "Deployment-ID" field, enter "gpt-4o-mini" or another model that is available in Azure OpenAI.
6. In the "api-version" field, enter "2024-05-01-preview".
7. In the "Advanced parameters" field, check "Authentication", "Subscription key", and "body".
7. In the "Body" field, enter

```
{
  "messages": [
    {
      "role": "system",
      "content": "@{outputs('policiesapi')}"
    },
    {
      "role": "user", 
      "content": "@{triggerBody()?['prompt']}"
    }
  ]
}
```

8. In the "Authentication Types" section, select "Managed identity". In the "Managed identity" section, select "System-assigned managed identity", then in the Audience field, enter https://management.azure.com/. In the "Subscription key" field, enter the key you generated in section "3.1".
9. Test the Azure Logic App operation. Select the "Run" button, then "Run with payload". In the "Body" section, enter the following code

```
{
    "prompt": "Please provide the id and prices of insurance policies. Write which policy is better to choose?"
}
```

https://learn.microsoft.com/en-us/azure/logic-apps/monitor-logic-apps-overview

10. Wait a few seconds for a response from Azure OpenAI and click on "View monitoring view". Check the event flow in Azure Logic App. Go to the block named "policies-ai" and in the "Outputs" section, find "Body", check the response from the model.
11. Additional task: change policies in "Azure API Management" and "Azure Logic App" configuration so that "Azure Logic App" for "policiesapi" also uses "Managed Identity".

---

## 7. TRANSFORMATION/ANONYMIZATION

### 7.1 Applying Transformation Policies

https://learn.microsoft.com/en-us/azure/api-management/json-to-xml-policy

1. Go to "APIs" and select "policies-ai"
2. Go to "Policies"
3. In the XML editor, in the `<outbound>` section after the `<base />` tag, add a JSON to XML conversion policy:

```
        <json-to-xml apply="always" consider-accept-header="false" parse-date="false" />
```

### 7.2 Adding Data Anonymization Policy

https://learn.microsoft.com/en-us/azure/api-management/find-and-replace-policy

1. While still in the policy editor, add in the `<outbound>` section after the transformation policy:

```
        <find-and-replace from="123456" to="xxxxxx" />
```

2. Click "Save"

### 7.3 Testing Transformation and Anonymization v1

1. Run Azure Logic App as in section 6.3.9 and verify that currently the "Body" in "Outputs" is in XML format, and that the policy id has been replaced from 123456 to xxxxxx.

---

### 7.4 Changing find-and-replace to RegularExpressions

1. In the policy editor, change 

```
        <find-and-replace from="123" to="xxx" />
```

to

https://learn.microsoft.com/en-us/azure/api-management/api-management-policy-expressions

```
        <set-body>@{
        string body = context.Response.Body.As<string>(preserveContent: true);
        body = System.Text.RegularExpressions.Regex.Replace(body,  @"\b\d{6}\b", "xxxxxx");
        return body;}
        </set-body>
```
2. Click "Save"
3. Accept the "Warning" message.

### 7.5 Testing Transformation and Anonymization v2

1. Run Azure Logic App as in section 6.3.9 and verify that currently the "Body" in "Outputs" is in XML format, and that all policy ids have been replaced from 123456 and 123457 to xxxxxx.

## 8. MONITORING AND DIAGNOSTICS IN APIM

### 8.1 Configuring Application Insights

https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-app-insights?tabs=rest

1. If you don't already have an Application Insights resource, create one:
    - Search for "Application Insights" in Azure Portal
    - Click "+ Create"
    - Fill out the form and create the resource
2. Go to the API Management resource
3. In the side menu, search for "Application Insights", add the previously created Application Insights resource.
4. Then in the side menu, select "APIs", then "All APIs".
5. Click "Settings" and click "Enable" for "Application Insight".
6. In the "Destination" field, select the previously created "Application Insight"
7. In the "Verbosity" field, select "Verbose"
8. Click "Save"

### 8.2 Configuring Logging and Tracing

https://learn.microsoft.com/en-us/azure/api-management/trace-policy

1. Go to "APIs" and select "policies-ai"
2. Select the "Policies" tab
3. In the XML editor, add in the `<inbound>` section after `<base />`:

```xml
        <!--Use consumer correlation id or generate new one-->
        <set-variable name="correlation-id" value="@(context.Request.Headers.GetValueOrDefault("x-ms-client-tracking-id", Guid.NewGuid().ToString()))" />
        <!--Set header for end-to-end correlation-->
        <set-header name="x-correlation-id" exists-action="override">
            <value>@((string)context.Variables["correlation-id"])</value>
        </set-header>
        <trace source="API Management Trace">
            <message>@{
    return "Starting request processing " + context.Request.Method + " " + context.Request.Url.Path;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
```

4. In the `<outbound>` section after `<base />`, add:

```xml
        <trace source="API Management Trace">
            <message>@{
    return "Completed processing, status: " + context.Response.StatusCode;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
```

5. Click "Save"

The complete policy should look like this:

```xml
<policies>
    <inbound>
        <base />
        <!--Use consumer correlation id or generate new one-->
        <set-variable name="correlation-id" value="@(context.Request.Headers.GetValueOrDefault("x-ms-client-tracking-id", Guid.NewGuid().ToString()))" />
        <!--Set header for end-to-end correlation-->
        <set-header name="x-correlation-id" exists-action="override">
            <value>@((string)context.Variables["correlation-id"])</value>
        </set-header>
        <trace source="API Management Trace">
            <message>@{
    return "Starting request processing " + context.Request.Method + " " + context.Request.Url.Path;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
        <validate-azure-ad-token tenant-id="xxxxxxxxxxxxxxxxxxxx">
            <client-application-ids>
                <application-id>xxxxxxxxxxxxxxxx</application-id>
            </client-application-ids>
        </validate-azure-ad-token>
        <azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
        <set-backend-service id="apim-generated-policy" backend-id="policies-ai-ai-endpoint" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <trace source="API Management Trace">
            <message>@{
    return "Completed processing, status: " + context.Response.StatusCode;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
```

5. Click "Save"

The complete policy should look like this:

```xml
<policies>
    <inbound>
        <base />
        <!--Use consumer correlation id or generate new one-->
        <set-variable name="correlation-id" value="@(context.Request.Headers.GetValueOrDefault("x-ms-client-tracking-id", Guid.NewGuid().ToString()))" />
        <!--Set header for end-to-end correlation-->
        <set-header name="x-correlation-id" exists-action="override">
            <value>@((string)context.Variables["correlation-id"])</value>
        </set-header>
        <trace source="API Management Trace">
            <message>@{
    return "Starting request processing " + context.Request.Method + " " + context.Request.Url.Path;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
        <validate-azure-ad-token tenant-id="xxxxxxxxxxxxxxxxxxxx">
            <client-application-ids>
                <application-id>xxxxxxxxxxxxxxxx</application-id>
            </client-application-ids>
        </validate-azure-ad-token>
        <azure-openai-token-limit counter-key="@(context.Subscription.Id)" tokens-per-minute="10000" estimate-prompt-tokens="true" />
        <set-backend-service id="apim-generated-policy" backend-id="policies-ai-ai-endpoint" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <trace source="API Management Trace">
            <message>@{
    return "Completed processing, status: " + context.Response.StatusCode;
  }</message>
            <metadata name="User-Agent" value="@(context.Request.Headers.GetValueOrDefault("User-Agent", ""))" />
            <metadata name="Subscription-Id" value="@(context.Subscription?.Id ?? "anonymous")" />
            <metadata name="correlation-id" value="@((string)context.Variables["correlation-id"])" />
        </trace>
        <json-to-xml apply="always" consider-accept-header="false" parse-date="false" />
        <set-body>@{
        string body = context.Response.Body.As<string>(preserveContent: true);
        body = System.Text.RegularExpressions.Regex.Replace(body,  @"\b\d{6}\b", "xxxxxx");
        return body;}</set-body>
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

### 8.3 Analyzing Metrics and Logs

https://learn.microsoft.com/en-us/azure/azure-monitor/app/transaction-search-and-diagnostics?tabs=transaction-search

1. Execute several queries to the API
2. Go to the Application Insights resource
3. In the side menu, select "Investigate", then "Search"
4. Check what the results look like.

---

## 9. Familiarize Yourself with Other Policies

On the page https://learn.microsoft.com/en-us/azure/api-management/api-management-policies, you can familiarize yourself with the complete list of policies available in Azure API Management. It's worth checking policies such as Caching or Rewrite URL. For Azure OpenAI, it's also worth familiarizing yourself with information about semantic caching. You can find more information on this page: https://learn.microsoft.com/en-us/azure/api-management/azure-openai-enable-semantic-caching

---

## 10. Smart Load Balancing for Azure AI Foundry

## Introduction

Smart Load Balancing differs from traditional round-robin through:
- **Immediate response to 429 errors** (Too Many Requests) - no switching delays
- **Respecting Retry-After header** - automatic restoration of backends after the time specified by Azure AI Foundry
- **Priority groups** - e.g., PTU (Provisioned Throughput) as Priority 1, S0 as fallback Priority 2
- **Handling 401/5xx errors** - automatic switch to healthy backend

**Reference documentation:** https://learn.microsoft.com/en-us/samples/azure-samples/openai-apim-lb/openai-apim-lb/

---

## 10.1 Solution Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           APIM Policy                    │
                    │  ┌─────────────────────────────────┐    │
                    │  │      listBackends (cached)       │    │
                    │  │  ┌───────────────────────────┐   │    │
HTTP Client ───────►│  │  │ Backend 1 (Priority 1)    │   │────► OpenAI Primary
(script/app)        │  │  │ url, isThrottling         │   │    │
                    │  │  │ retryAfter                │   │    │
                    │  │  ├───────────────────────────┤   │    │
                    │  │  │ Backend 2 (Priority 2)    │   │────► OpenAI Secondary
                    │  │  │ ...                       │   │    │
                    │  │  └───────────────────────────┘   │    │
                    │  └─────────────────────────────────┘    │
                    └─────────────────────────────────────────┘
```

---

## 10.2 Your Azure AI Foundry Resources

For this task, you will use **two Azure AI Foundry (OpenAI) resources** prepared for you:

| Backend | Resource Name | Region | Priority | Role |
|---------|--------------|--------|-----------|------|
| **Primary** | `aoai-azureclubworkshopint-{usernumber}-01` | France Central | 1 | Main endpoint |
| **Secondary** | `aoai-azureclubworkshopint-{usernumber}-02` | Sweden Central | 2 | Backup (failover) |

> 📋 **Cheat Sheet**: Check the document with data received from the organizers. You will find exact resource names and endpoints for your user number `{usernumber}`.

### Where to Find Azure AI Foundry Endpoint?

If you need to verify the endpoint:

1. Go to **Azure AI Foundry portal** (https://ai.azure.com)
2. Find the Azure OpenAI resource (e.g., `aoai-azureclubworkshopint-{usernumber}-01`)
3. In the **Models** → **Deployments** section, find the endpoint
4. Alternatively in **Azure Portal** → **Resource Groups** → `rg-azureclubworkshopint-{usernumber}` → AI resource → **Keys and Endpoint**

### URL Format

Replace `{usernumber}` with your user number (e.g., `05`):

```
Primary:   https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/
Secondary: https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/
```

**Example for user 05:**
```
Primary:   https://aoai-azureclubworkshopint-05-01.cognitiveservices.azure.com/
Secondary: https://aoai-azureclubworkshopint-05-02.cognitiveservices.azure.com/
```

---

## 10.3 Adding Second Azure AI Foundry Backend to APIM

In previous tasks (section 2), you added one Azure AI Foundry resource as a backend (Primary) to APIM. For Smart Load Balancing, you need **two backends**, so now we'll add the second resource (Secondary).

### Step 1: Verify Existing Backend (Primary)

1. Go to your **Azure API Management**
2. In the side menu, select **"Backends"**
3. You should see a backend named similar to `policies-ai-openai-endpoint` - this is your **Primary backend** from task 2
4. Click on it and note:
   - **Backend name** (e.g., `policies-ai-openai-endpoint`)
   - **Runtime URL** (e.g., `https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/openai`)

### Step 2: Adding Second Backend (Secondary)

1. In the **"Backends"** section, click **"+ Add"**
2. Fill out the form:
   - **Name**: `policies-ai-openai-endpoint-secondary`
   - **Type**: Custom URL
   - **Runtime URL**: `https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/openai`
     
     > ⚠️ Replace `{usernumber}` with your user number (e.g., `05`)
   
3. In the **"Authorization credentials"** section:
   - Leave default settings (no additional authorization - we'll use Managed Identity in the policy)
   
4. Click **"Create"**

### Step 3: Verify Both Backends

After adding, in the **"Backends"** section you should see **two entries**:

| Backend Name | Runtime URL | Role |
|-------------|-------------|------|
| `policies-ai-openai-endpoint` | `https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/openai` | Primary |
| `policies-ai-openai-endpoint-secondary` | `https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/openai` | Secondary |

> 💡 **Note**: In this Smart Load Balancing task, we don't use backends defined in APIM directly (via `<set-backend-service backend-id="...">`), but dynamically set the URL in the policy. However, adding backends is good practice for clarity and possible future extensions.

---

## 10.4 Granting Managed Identity Permissions to Both Azure AI Foundry Resources

Make sure that your API Management's Managed Identity has access to **both** Azure AI Foundry resources. In task 2, you granted permissions only to Primary - now you must repeat this for Secondary.

### Permissions for Primary (verification)

Permissions to Primary should already be granted from task 2. You can verify this:

1. Go to Azure AI Foundry **Primary** resource (e.g., `aoai-azureclubworkshopint-{usernumber}-01`)
2. Select **"Access control (IAM)"**
3. Click **"Role assignments"**
4. Check that your APIM has the **"Cognitive Services OpenAI User"** role

### Permissions for Secondary (new)

1. Go to Azure AI Foundry **Secondary** resource (e.g., `aoai-azureclubworkshopint-{usernumber}-02`)
2. Select **"Access control (IAM)"**
3. Click **"+ Add"** and select **"Add role assignment"**
4. Select the **"Cognitive Services OpenAI User"** role
5. In the **"Members"** tab, select **"Managed identity"**
6. Click **"+ Select members"**
7. In the "Managed identity" filter, select **"API Management"**
8. Find and select your APIM (e.g., `apim-azureclubworkshopint-{usernumber}`)
9. Click **"Select"**, then **"Review + assign"**

> ⚠️ **Important**: Without this step, the Smart Load Balancing policy will return a 401 Unauthorized error when trying to use the Secondary backend!

---

## 10.5 Configuring Smart Load Balancing Policy

### Key Policy Features

This policy implements **automatic retry** on 429/5xx errors:

| Feature | Description |
|---------|-----|
| **Automatic retry** | On 429 immediately sends request to another backend |
| **Transparency for client** | Client always gets 200 (if any backend is working) |
| **Header `x-retry-count`** | Shows how many retries were needed |
| **Header `x-served-by`** | Shows which backend served the request |
| **Up to 3 attempts** | Maximum 3 attempts before returning an error |

### Step by Step

> ⚠️ **IMPORTANT**: In this step **replace the ENTIRE existing policy** with a new version. Don't try to modify the existing policy - just select all (Ctrl+A) and paste the new code. This will avoid problems with missing elements.

> 💾 **Optional - backup**: If you want to be able to return to the previous policy version, before replacing, copy the current editor content (Ctrl+A, Ctrl+C) and paste it into a notepad or text file (e.g., `polityka-backup.xml`).

1. Go to **"APIs"** and select **"policies-ai"
2. Go to the **"Inbound processing"** section, click on **`</>`**
3. **Select ALL content** in the editor (Ctrl+A) and **delete** it
4. Paste the following XML code (Ctrl+V):

```xml
<policies>
    <inbound>
        <base />
        
        <!-- ============================================== -->
        <!-- SMART LOAD BALANCING - with automatic retry -->
        <!-- ============================================== -->
        
        <!-- Initialize attempt counter (max 3) -->
        <set-variable name="remainingAttempts" value="@(3)" />
        
        <!-- Get backend list from cache -->
        <cache-lookup-value key="@("listBackends-" + context.Api.Id)" variable-name="listBackends" />
        
        <choose>
            <when condition="@(!context.Variables.ContainsKey("listBackends"))">
                <set-variable name="listBackends" value="@{
                    // Backend definition:
                    // - url: Azure AI Foundry endpoint
                    // - priority: 1 = Primary, 2 = Secondary (fallback)
                    // - isThrottling: whether backend returns 429
                    // - retryAfter: when backend will be available again

                    JArray backends = new JArray();
                    
                    // Primary backend - Priority 1
                    backends.Add(new JObject()
                    {
                        { "url", "https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/" },
                        { "priority", 1},
                        { "isThrottling", false }, 
                        { "retryAfter", DateTime.MinValue } 
                    });

                    // Secondary backend - Priority 2 (fallback)
                    backends.Add(new JObject()
                    {
                        { "url", "https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/" },
                        { "priority", 2},
                        { "isThrottling", false },
                        { "retryAfter", DateTime.MinValue }
                    });

                    return backends;   
                }" />
                
                <cache-store-value key="@("listBackends-" + context.Api.Id)" value="@((JArray)context.Variables["listBackends"])" duration="60" />
            </when>
        </choose>

        <!-- Health Check - restore backends after retryAfter time -->
        <set-variable name="listBackends" value="@{
            JArray backends = (JArray)context.Variables["listBackends"];

            for (int i = 0; i < backends.Count; i++)
            {
                JObject backend = (JObject)backends[i];
                if (backend.Value<bool>("isThrottling") && DateTime.Now >= backend.Value<DateTime>("retryAfter"))
                {
                    backend["isThrottling"] = false;
                    backend["retryAfter"] = DateTime.MinValue;
                }
            }
            return backends; 
        }" />

        <!-- Select best backend (lowest priority among healthy ones) -->
        <set-variable name="backendIndex" value="@{
            JArray backends = (JArray)context.Variables["listBackends"];
            int selectedPriority = Int32.MaxValue;
            List<int> availableBackends = new List<int>();

            for (int i = 0; i < backends.Count; i++)
            {
                JObject backend = (JObject)backends[i];
                if (!backend.Value<bool>("isThrottling"))
                {
                    int priority = backend.Value<int>("priority");
                    if (priority < selectedPriority)
                    {
                        selectedPriority = priority;
                        availableBackends.Clear();
                        availableBackends.Add(i);
                    }
                    else if (priority == selectedPriority)
                    {
                        availableBackends.Add(i);
                    }
                }
            }

            if (availableBackends.Count == 0) { return 0; }
            return availableBackends[new Random().Next(availableBackends.Count)];
        }" />

        <set-variable name="backendUrl" value="@{
            JArray backends = (JArray)context.Variables["listBackends"];
            int index = context.Variables.GetValueOrDefault<int>("backendIndex");
            return ((JObject)backends[index])["url"].ToString();
        }" />

        <!-- Managed Identity Authentication -->
        <authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="msi-access-token" ignore-error="false" />
        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
        </set-header>

        <!-- Set backend URL -->
        <set-backend-service base-url="@((string)context.Variables["backendUrl"] + "openai")" />
        
        <!-- Save request body for potential retry -->
        <set-variable name="originalBody" value="@(context.Request.Body.As<string>(preserveContent: true))" />

    </inbound>
    
    <backend>
        <forward-request buffer-request-body="true" />
    </backend>
    
    <outbound>
        <base />
        
        <!-- ============================================== -->
        <!-- AUTOMATIC RETRY on 429/5xx               -->
        <!-- ============================================== -->
        <choose>
            <when condition="@(context.Response != null && (context.Response.StatusCode == 429 || context.Response.StatusCode >= 500))">
                
                <!-- Mark current backend as throttling -->
                <set-variable name="listBackends" value="@{
                    JArray backends = (JArray)context.Variables["listBackends"];
                    int currentBackendIndex = context.Variables.GetValueOrDefault<int>("backendIndex");
                    int retryAfter = 10;
                    
                    if (context.Response.Headers.ContainsKey("Retry-After"))
                    {
                        int.TryParse(context.Response.Headers.GetValueOrDefault("Retry-After", "10"), out retryAfter);
                    }
                    
                    JObject backend = (JObject)backends[currentBackendIndex];
                    backend["isThrottling"] = true;
                    backend["retryAfter"] = DateTime.Now.AddSeconds(retryAfter);
                    return backends;      
                }" />
                
                <cache-store-value key="@("listBackends-" + context.Api.Id)" value="@((JArray)context.Variables["listBackends"])" duration="60" />
                
                <!-- Decrease attempt counter -->
                <set-variable name="remainingAttempts" value="@(context.Variables.GetValueOrDefault<int>("remainingAttempts") - 1)" />
                
                <!-- Check if backends are available and if we still have attempts -->
                <choose>
                    <when condition="@{
                        int remaining = context.Variables.GetValueOrDefault<int>("remainingAttempts");
                        if (remaining <= 0) { return false; }
                        JArray backends = (JArray)context.Variables["listBackends"];
                        for (int i = 0; i < backends.Count; i++)
                        {
                            if (!((JObject)backends[i]).Value<bool>("isThrottling")) { return true; }
                        }
                        return false;
                    }">
                        
                        <trace source="Smart-LB">
                            <message>@("Failover from: " + (string)context.Variables["backendUrl"])</message>
                        </trace>
                        
                        <!-- Select new backend -->
                        <set-variable name="backendIndex" value="@{
                            JArray backends = (JArray)context.Variables["listBackends"];
                            int selectedPriority = Int32.MaxValue;
                            List<int> availableBackends = new List<int>();
                            
                            for (int i = 0; i < backends.Count; i++)
                            {
                                JObject backend = (JObject)backends[i];
                                if (!backend.Value<bool>("isThrottling"))
                                {
                                    int priority = backend.Value<int>("priority");
                                    if (priority < selectedPriority)
                                    {
                                        selectedPriority = priority;
                                        availableBackends.Clear();
                                        availableBackends.Add(i);
                                    }
                                    else if (priority == selectedPriority)
                                    {
                                        availableBackends.Add(i);
                                    }
                                }
                            }
                            
                            if (availableBackends.Count == 0) { return 0; }
                            return availableBackends[new Random().Next(availableBackends.Count)];
                        }" />

                        <set-variable name="backendUrl" value="@{
                            JArray backends = (JArray)context.Variables["listBackends"];
                            int index = context.Variables.GetValueOrDefault<int>("backendIndex");
                            return ((JObject)backends[index])["url"].ToString();
                        }" />
                        
                        <!-- Send request to new backend -->
                        <send-request mode="new" response-variable-name="retryResponse" timeout="60" ignore-error="false">
                            <set-url>@((string)context.Variables["backendUrl"] + "openai" + context.Request.OriginalUrl.Path.Substring(context.Api.Path.Length) + context.Request.OriginalUrl.QueryString)</set-url>
                            <set-method>@(context.Request.Method)</set-method>
                            <set-header name="Authorization" exists-action="override">
                                <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
                            </set-header>
                            <set-header name="Content-Type" exists-action="override">
                                <value>application/json</value>
                            </set-header>
                            <set-body>@((string)context.Variables["originalBody"])</set-body>
                        </send-request>
                        
                        <!-- Replace response with retry response -->
                        <return-response response-variable-name="retryResponse">
                            <set-header name="x-served-by" exists-action="override">
                                <value>@((string)context.Variables["backendUrl"])</value>
                            </set-header>
                            <set-header name="x-retry-count" exists-action="override">
                                <value>@((3 - context.Variables.GetValueOrDefault<int>("remainingAttempts")).ToString())</value>
                            </set-header>
                        </return-response>
                        
                    </when>
                </choose>
                
            </when>
        </choose>
        
        <!-- Header showing which backend served the request -->
        <set-header name="x-served-by" exists-action="override">
            <value>@((string)context.Variables["backendUrl"])</value>
        </set-header>
        
    </outbound>
    
    <on-error>
        <base />
    </on-error>
</policies>
```

5. Click **"Save"**

> ✅ **Done!** The Smart Load Balancing policy is now active. Go to the next step to customize backend URLs.

---

## 10.6 Customizing Backend URLs

⚠️ **Important:** Before saving the policy, replace the placeholder `{usernumber}` with your user number.

1. In the `listBackends` section, find the lines with URLs:
   ```csharp
   { "url", "https://aoai-azureclubworkshopint-{usernumber}-01.cognitiveservices.azure.com/" },
   ...
   { "url", "https://aoai-azureclubworkshopint-{usernumber}-02.cognitiveservices.azure.com/" },
   ```

2. Replace `{usernumber}` with your user number (e.g., `05`):
   ```csharp
   { "url", "https://aoai-azureclubworkshopint-05-01.cognitiveservices.azure.com/" },
   ...
   { "url", "https://aoai-azureclubworkshopint-05-02.cognitiveservices.azure.com/" },
   ```

> 📋 **Tip**: Check the cheat sheet received from the organizers - you'll find the exact URLs of your Azure AI Foundry resources there.

---

## 10.7 Test Preparation - Reducing TPM Limit

To test Smart Load Balancing functionality, we need to trigger a 429 error (Too Many Requests) on the Primary backend. To do this, we will **temporarily reduce the TPM limit** on the Primary deployment to the minimum value.

### Step 1: Reduce TPM on Primary OpenAI

1. Go to **Azure AI Foundry portal** (https://ai.azure.com)
2. Select your Azure AI Foundry **Primary** resource (e.g., `aoai-azureclubworkshopint-XX-01`)
3. Go to the **Deployments** section
4. Find the `gpt-4o-mini` deployment and click on it
5. Click **Edit deployment** or the edit icon
6. In the **Tokens per Minute Rate Limit** field, change the value to **1K** (1000)
7. Click **Save**

> 💡 **Explanation**: A 1K TPM limit means ~10-15 short requests per minute. With intensive traffic, we will quickly reach the limit and receive a 429 error.

### Step 2: Verify Secondary Limit (optional)

Make sure that Secondary Azure AI Foundry has a higher limit (e.g., 10K TPM) so it can handle traffic after failover:

1. Go to the Azure AI Foundry **Secondary** resource (e.g., `aoai-azureclubworkshopint-XX-02`)
2. Check that the `gpt-4o-mini` deployment has a **10K TPM** limit or higher

---

## 10.8 Testing Smart Load Balancing

To test Smart Load Balancing, we will use the **PowerShell script** `Test-SmartLoadBalancing.ps1`, which automatically:
- Retrieves an Azure AD token from Azure CLI (no subscription key required!)
- Sends multiple parallel requests
- Displays detailed results with information about retry and failover

> ⚠️ **IMPORTANT - Disable subscription requirement**: Before running the test, make sure that the "Subscription required" option is **disabled** for the `policies-ai` API in APIM.
>
> **How to check/disable:**
> 1. Go to **Azure API Management** → **APIs** → **policies-ai**
> 2. Click the **"Settings"** tab
> 3. In the **"Subscription"** section, uncheck the **"Subscription required"** checkbox
> 4. Click **"Save"**
>
> This allows the script to use an Azure AD token instead of an APIM subscription key.

### New Diagnostic Headers

The Smart Load Balancing policy adds additional headers to responses:

| Header | Description | Example |
|--------|-------------|---------|
| `x-served-by` | URL of the backend that served the request | `https://aoai-azureclubworkshopint-XX-01.cognitiveservices.azure.com/` |
| `x-retry-count` | How many retries were needed (empty = 0) | `1` (indicates failover to another backend) |

### Running the Test

1. **Open PowerShell terminal** in the workshop materials directory

2. **Make sure you are logged into Azure:**
   ```powershell
   az login
   ```

3. **Run the test script** (replace `usernumber` with your user number):
   ```powershell
   .\scripts\Test-SmartLoadBalancing.ps1 -TeamNumber "usernumber" -RequestCount 25
   ```

   > 💡 **Recommendation**: The value of **25 requests** is optimal for testing failover. With a smaller number (e.g., 10-15), the TPM limit on Primary may not be exceeded, and with a larger number, the test takes unnecessarily long.

### Sample Output

```
╔════════════════════════════════════════════════════════════════╗
║       SMART LOAD BALANCING TEST - Azure API Management         ║
╚════════════════════════════════════════════════════════════════╝

[CONFIG] Test configuration:
  • User:              05
  • APIM:              apim-azureclubworkshopint-05
  • Request count:     25
  • Parallel mode:     True

[INFO] Retrieving Azure AD token from Azure CLI...
[OK] Azure AD token retrieved

[INFO] Starting test...

[MODE] Sending 20 requests in PARALLEL...

╔════════════════════════════════════════════════════════════════╗
║                        TEST RESULTS                            ║
╚════════════════════════════════════════════════════════════════╝

[DETAILS] Per-request results:
─────────────────────────────────────────────────────────────────
  Request  1: PRIMARY              
  Request  2: PRIMARY              
  Request  3: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  4: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  5: PRIMARY              
  ...

─────────────────────────────────────────────────────────────────
[STATISTICS]
─────────────────────────────────────────────────────────────────
  Test duration:          12.3 seconds
  Total requests:         20

  PRIMARY (Priority 1):   15 requests
  SECONDARY (Priority 2): 5 requests
  ERRORS:                 0 requests
  With automatic RETRY:   5 requests

─────────────────────────────────────────────────────────────────
[SUMMARY]
─────────────────────────────────────────────────────────────────

  ✅ SUCCESS! Smart Load Balancing WORKS CORRECTLY!

  What happened:
  • Primary backend reached TPM limit (429)
  • Policy automatically performed RETRY to Secondary
  • Client received 200 OK response (didn't see 429 error)

  The 'x-retry-count' header shows how many retries were needed.
```

### Result Interpretation

| Result | Meaning |
|--------|---------|
| `PRIMARY` | Request served by Primary (Priority 1) - normal situation |
| `SECONDARY (retry: 1)` | Primary returned 429, automatic retry to Secondary - **failover worked!** |
| `ERROR 429` | All backends throttling - increase TPM limit on Secondary |
| `ERROR 401` | Managed Identity issue - check APIM permissions to OpenAI |

### Script Parameters

| Parameter | Description | Default value | Recommendation |
|----------|-------------|---------------|----------------|
| `-UserNumber` | Your user number (required) | - | - |
| `-RequestCount` | Number of requests to send | 20 | **25** |
| `-Parallel` | Whether to send in parallel | `$true` | `$true` |

### What to Observe in Results?

1. **Basic operation**: First requests should go to **PRIMARY**
2. **Failover**: When Primary reaches TPM limit (1K), you'll see a switch to **SECONDARY** with the `(retry: 1)` marker
3. **Automatic restoration**: After ~10-60 seconds, Primary will return to use

> 💡 **Key difference from traditional load balancing**: Thanks to automatic retry, **the client never sees a 429 error** as long as at least one backend is available!

---

## 10.9 Observing Load Balancing - Verification Methods

There are several ways to observe Smart Load Balancing in action. Below we describe all methods - from the simplest to the most advanced.

### Method 1: Test Script Results (⭐ RECOMMENDED)

**Easiest method** - the `Test-SmartLoadBalancing.ps1` script automatically displays:

- **Per-request**: which backend served each request (PRIMARY/SECONDARY)
- **Failover**: `(retry: X)` marker when automatic switching occurred
- **Statistics**: summary of how many requests each backend served

Sample result excerpt:
```
  Request  1: PRIMARY              
  Request  2: PRIMARY              
  Request  3: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  4: SECONDARY   (retry: 1)  ← FAILOVER!
  Request  5: PRIMARY              
```

---

### Method 2: Application Insights - Transaction Search

Application Insights collects detailed logs from APIM, including traces and metrics.

1. Go to **Application Insights** resource (e.g., `appi-azureclubworkshopint-XX`)
2. In the menu select **"Investigate"** → **"Transaction search"**
3. Set time range to last 30 minutes
4. Search for requests to the `policies-ai` API
5. In transaction details you will find:
   - Request URL (shows backend)
   - Custom properties with headers
   - Trace messages: "Backend throttling detected. Switching to another backend."

---

### Method 3: Azure AI Foundry Metrics

Per-resource Azure AI Foundry metrics show how many requests each backend served.

1. Go to **Azure AI Foundry portal** (https://ai.azure.com)
2. Select Azure AI Foundry resource (Primary or Secondary)
3. Go to **Metrics** in the side menu
4. Add metric: **"Azure OpenAI Requests"** (metric name remains the same)
5. Set aggregation: **Count**
6. Range: last 30 minutes, granularity 1 minute

**Interpretation**:
- **Primary** (`aoai-azureclubworkshopint-XX-01`): many requests, then sudden drop
- **Secondary** (`aoai-azureclubworkshopint-XX-02`): initially 0, then increase (failover)

---

### Method 4: Log Analytics - KQL Query (Advanced)

> ⚠️ **Required configuration**: To use this method, APIM must have diagnostics enabled to Log Analytics with `GatewayLogs` logs in **Resource-specific** mode.
> 
> **Note about delays:**
> - `requests` (Application Insights) - data available **immediately** (~1-2 minutes)
> - `ApiManagementGatewayLogs` - data available with **10-20 minute** delay

For detailed analysis, use KQL queries:

> ⚠️ **Important**: Run `requests` queries in **Application Insights** (`appi-azureclubworkshopint-XX`), and `ApiManagementGatewayLogs` queries in **Log Analytics Workspace** (`log-azureclubworkshopint-XX`).
>
> **Table naming differences:**
> | Application Insights | Log Analytics (cross-workspace) |
> |---------------------|--------------------------------|
> | `requests` | `AppRequests` |
> | `timestamp` | `TimeGenerated` |
> | `url` | `Url` |
> | `resultCode` | `ResultCode` |

### Queries in Application Insights

1. Go to **Application Insights** resource (e.g., `appi-azureclubworkshopint-XX`)
2. Select **"Logs"** in the side menu
3. Paste the query below:

**Query 1: Application Insights - request distribution** (⭐ works immediately):

```kusto
// Request distribution to policies-ai API over time
requests
| where timestamp > ago(2h)
| where url contains "policies-ai"
| summarize RequestCount = count() by bin(timestamp, 1m), resultCode
| render timechart
```

### Queries in Log Analytics Workspace

1. Go to **Log Analytics Workspace** resource (e.g., `log-azureclubworkshopint-XX`)
2. Select **"Logs"** in the side menu
3. Paste the query below:

**Query 2: APIM Gateway Logs - backend summary** (⭐ RECOMMENDED, requires ~15 min for data to appear):

> 💡 **Adjust time range**: By default, queries use `ago(2h)` (last 2 hours). If your tests were earlier, increase this range, e.g., `ago(4h)` or `ago(6h)`. Each participant works at their own pace!

```kusto
// Request summary per backend - CLEARLY shows distribution!
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)  // ← change to ago(4h) or ago(6h) if needed
| where ApiId == "policies-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize RequestCount = count() by BackendHost
| order by RequestCount desc
```

**Sample result:**
| BackendHost | RequestCount |
|-------------|--------------|
| `aoai-azureclubworkshopint-XX-01.cognitiveservices.azure.com` | 31 |
| `aoai-azureclubworkshopint-XX-02.cognitiveservices.azure.com` | 9 |

> 👆 **Interpretation**: Primary (`XX-01`) served 31 requests, Secondary (`XX-02`) served 9 requests after failover!

**Query 3: Latency comparison between backends** ⭐:

```kusto
// Compare average response time (ms) per backend
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)
| where ApiId == "policies-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize 
    AvgLatency = round(avg(todouble(BackendTime)), 0),
    MaxLatency = max(todouble(BackendTime)),
    MinLatency = min(todouble(BackendTime)),
    RequestCount = count() 
    by BackendHost
| order by RequestCount desc
```

**Sample result:**
| BackendHost | AvgLatency | MaxLatency | MinLatency | RequestCount |
|-------------|------------|------------|------------|--------------|
| `XX-01.cognitiveservices.azure.com` | **7653** | 56544 | 197 | 31 |
| `XX-02.cognitiveservices.azure.com` | **281** | 367 | 257 | 9 |

> 👆 **Interpretation**: Primary (`XX-01`) has significantly higher latency (~7.6s) because it's throttling and waiting for retry. Secondary (`XX-02`) responds quickly (~280ms) because it has spare capacity!

---

**Query 4: Success vs Throttled vs Errors per backend** ⭐:

```kusto
// Status code distribution per backend - shows how many requests were throttled
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)
| where ApiId == "policies-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize 
    Success = countif(BackendResponseCode == "200"),
    Throttled = countif(BackendResponseCode == "429"),
    Errors = countif(BackendResponseCode != "200" and BackendResponseCode != "429")
    by BackendHost
```

**Sample result:**
| BackendHost | Success | Throttled | Errors |
|-------------|---------|-----------|--------|
| `XX-01.cognitiveservices.azure.com` | 23 | **8** | 0 |
| `XX-02.cognitiveservices.azure.com` | 9 | 0 | 0 |

> 👆 **Interpretation**: Primary (`XX-01`) returned 429 error 8 times (throttling), but the policy automatically performed retry to Secondary - that's why the client always got 200!

---

**Query 5: APIM Gateway Logs - backend distribution over time** (chart):

```kusto
// Request distribution between backends over time (chart)
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ApiId == "policies-ai"
| extend BackendHost = tostring(split(BackendUrl, "/")[2])
| summarize RequestCount = count() by BackendHost, bin(TimeGenerated, 1m)
| render timechart
```

> 💡 **If `ApiManagementGatewayLogs` is empty**: The table is created automatically after enabling diagnostics, but first data appears with a 10-20 minute delay. Use `AppRequests` (in Application Insights) for immediate verification.

4. Click **"Run"**
5. The table/chart will show request distribution between backends

### Query in Application Insights (summary)

> ⚠️ **Note**: Run this query in **Application Insights** (`appi-azureclubworkshopint-XX`), not in Log Analytics!
>
> **Naming difference**: In Application Insights, the table is called `requests` (not `AppRequests`), and columns use camelCase (`timestamp`, `url`, `resultCode`).

**Query 6: Application Insights - summary table**:

```kusto
// Request summary per status code
// RUN IN: Application Insights → Logs
requests
| where timestamp > ago(2h)
| where url contains "policies-ai"
| summarize 
    TotalRequests = count(),
    SuccessfulRequests = countif(resultCode == "200"),
    FailedRequests = countif(resultCode != "200")
    by bin(timestamp, 5m)
| order by timestamp desc
```

> 💡 **Tip**: If you want to see detailed logs with `x-served-by` headers, use **Application Insights → Transaction Search** (Method 2) - there you'll see full details of each request.

---

### Observation Methods Summary

| Method | Ease | Detail Level | Best Use Case |
|--------|------|--------------|---------------|
| **Test script** | ⭐⭐⭐ Easy | Basic | Quick per-request verification |
| **App Insights** | ⭐⭐ Medium | Medium | Traces and debugging |
| **OpenAI Metrics** | ⭐⭐ Medium | Per-resource | Overall load picture |
| **Log Analytics KQL** | ⭐ Advanced | Highest | Detailed analysis and reports |

---

## 10.10 Restoring Normal TPM Limit

⚠️ **After completing tests**, restore the normal TPM limit on Primary:

1. Go to **Azure AI Foundry portal** (https://ai.azure.com)
2. Select the Azure AI Foundry **Primary** resource
3. Edit the `gpt-4o-mini` deployment
4. Change **Tokens per Minute Rate Limit** back to **10K** or higher
5. Click **Save**

> 💡 This step is important to ensure normal throughput for subsequent tasks or users.

---

## 10.11 How the Smart Load Balancing Algorithm Works

### Flow for Each Request:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INBOUND PROCESSING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Initialization: remainingAttempts = 3                                   │
│  2. Retrieve backend list from cache (or initialize)                       │
│  3. Health Check - restore backends after retryAfter time                  │
│  4. Select backend with lowest priority among healthy ones                 │
│  5. Save originalBody (for potential retry)                                │
│  6. Forward request to selected backend                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          OUTBOUND PROCESSING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  Response 200?                                                               │
│       │                                                                      │
│      YES ──────────────────────► Return response to client                  │
│       │                          + x-served-by header                        │
│      NO (429/5xx)                                                           │
│       │                                                                      │
│       ▼                                                                      │
│  1. Mark backend as throttling                                              │
│  2. remainingAttempts--                                                     │
│  3. Are remainingAttempts > 0 AND healthy backends available?               │
│       │                                                                      │
│      YES ──► Select new backend ──► send-request ──► return-response       │
│       │      + x-retry-count header                                         │
│      NO                                                                      │
│       │                                                                      │
│       ▼                                                                      │
│  Return original 429/5xx response                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Difference: Automatic Retry

**Traditional load balancing:**
- On 429, only marks backend as throttling
- Client gets 429 error
- Only **next request** goes to another backend

**Smart Load Balancing (this policy):**
- On 429, **immediately** selects another backend
- Sends **new request** to healthy backend (using `send-request`)
- Client gets **200 OK** with response
- `x-retry-count` header indicates how many retries were needed

### Maximum Number of Attempts

The policy performs **maximum 3 attempts**:
1. First attempt to Primary (Priority 1)
2. If 429 → retry to Secondary (Priority 2)
3. If 429 again → last attempt

If all attempts fail or all backends are throttling → client gets an error.

---

## 10.12 Key Policy Elements

| Element | Purpose |
|---------|---------|
| `remainingAttempts` | Attempt counter (max 3) |
| `listBackends` | JSON array with backends, priorities and status |
| `originalBody` | Saved request body for retry |
| `cache-store-value` | Maintains backend state between requests |
| `isThrottling` | Flag whether backend returns 429 |
| `retryAfter` | Timestamp when backend will be healthy again |
| `priority` | Lower value = higher priority |
| `send-request` | Sends retry request to new backend |
| `return-response` | Replaces response with retry result |
| `x-served-by` | Header - which backend served request |
| `x-retry-count` | Header - how many retries were performed |

---

## 10.13 Extensions (Optional)

### Adding a Third Backend

To add another backend, in the `listBackends` section add:

```xml
backends.Add(new JObject()
{
    { "url", "https://aoai-azureclubworkshopint-XX-03.cognitiveservices.azure.com/" },
    { "priority", 3},
    { "isThrottling", false },
    { "retryAfter", DateTime.MinValue }
});
```

### Using External Redis Cache

For environments with multiple APIM instances, consider using external Redis Cache:
https://learn.microsoft.com/azure/api-management/api-management-howto-cache-external

---

## Summary

After completing this task, your API:
- ✅ Automatically switches between Azure AI Foundry backends
- ✅ Respects rate limiting limits (429)
- ✅ Uses priorities (PTU before S0)
- ✅ Immediately responds to errors without delays
- ✅ Logs failover information to Application Insights

---

## 11. Exposing API as MCP for Agent in Microsoft Foundry

https://learn.microsoft.com/en-us/azure/api-management/export-rest-mcp-server

### 11.1 Exposing REST API as MCP

1. Go to your API Management
2. Then go to "MCP Servers"
3. Click on "Create MCP server", select "Expose an API as MCP server"
4. In the "API" field, select "PoliciesAPI"
5. In the "API operations" field, select "[Get] GetPolicies"
6. In the "Display name" field, enter the name "PoliciesAPIMCP"
7. In the "Name" field, enter the name "policiesapimcp"
9. In the "Description" field, enter "List of available policies".
10. Click "Create"
11. Enter the created MCP named "PoliciesAPIMCP" and note the "MCP server URL", e.g., https://xxxxxxx.azure-api.net/policiesapimcp/mcp

### 11.2 Agent Configuration in Microsoft Foundry

1. Go to "https://ai.azure.com".
2. Find your Microsoft Foundry where you want to create the agent. Use the new Microsoft Foundry interface. You'll find the Microsoft Foundry project selector in the upper left corner.
3. Go to the "Build" tab - you'll find this option in the upper right corner.
4. Click on "Create agent".
5. In the "Create an agent" field, enter "Agent-Insurance".
6. In the model selection field, choose any available model.
7. In the "Instructions" field, enter "You are an insurance agent, helping the client choose appropriate insurance. You have access to the list of insurances via the MCP server."
8. Go to the "Tools" option, select "Add", then "Custom". From the list, select "Model Context Protocol (MCP)", click "Create".
9. In the "Name" field, enter "PoliciesAPIMCP".
10. In the "Remote MCP Server endpoint" field, enter the MCP server address that you noted in step 11.1.11.
11. In the "Authentication" field, select "Microsoft Entra" - we will configure the policy on the API Management side in the next steps to allow this agent/project to access the MCP
12. In the "Type" field, select "Agent Identity"
13. Since Microsoft Foundry Agent Service v2 currently doesn't support adding multiple authentication methods simultaneously, we'll add a "Subscription key" to the query string. Change the "Remote MCP Server endpoint" to https://xxxxxxx.azure-api.net/policiesapimcp/mcp?api_key=xxxxxxxxxxxxxxxxxxxxx, where "Subscription key" was generated in step "3.1".
14. In the "Audience" field, enter "https://ai.azure.com". 

**Note:** In the next section, we will configure the `validate-azure-ad-token` policy on the API Management side, which will validate Microsoft Entra tokens sent by the agent. The "Audience" field specifies for which recipient the token should be issued, but in our implementation, we will focus mainly on validating the `client-application-id` (agent application identifier). Additionally, we use the Subscription key passed in the query string as an additional security layer.

15. Click "Create" to save the MCP configuration in the agent.
16. Click "Save".
17. You can test the agent by typing in the chat window "List available insurance policies?". Information should appear asking whether you accept executing the "getPolicies" query. Due to the unconfigured policy, the system should reject access to the MCP server.

### 11.3 MCP Server Policy Configuration

1. Go to "https://portal.azure.com", search for "Microsoft Foundry Project" where you created the agent from step 11.2. Go to "Microsoft Foundry Project", then click "JSON View" in the upper right corner and note the "agentIdentityId".
2. Another way to find "agentIdentityId" is to use the portal "https://entra.microsoft.com/" in the "Agent ID" tab. In the "All agent identities" tab, search for the identity with the name of your "Microsoft Foundry project" resource with the AgentIdentity suffix, e.g., "Aaifblamis01-aifblamis01-project01-AgentIdentity".
3. Go to your API Management.
4. Then go to "MCP Servers".
5. Go to the "MCP Server" named "policiesapimcp".
6. Go to the "Policies" tab.
7. Enter the policy below. Change the line in the policy regarding "tenant-id" and "<application-id>" - enter the "application-id" from step 11.3.1.

```xml
<!--
    - Policies are applied in the order they appear.
    - Position <base/> inside a section to inherit policies from the outer scope.
    - Comments within policies are not preserved.
-->
<!-- Add policies as children to the <inbound>, <outbound>, <backend>, and <on-error> elements -->
<policies>
	<!-- Throttle, authorize, validate, cache, or transform the requests -->
	<inbound>
		<base />
		<choose>
			<when condition="@(context.Request.Url.Query.ContainsKey("api_key"))">
				<!-- 2. Set the x-api-key header to the value from the query -->
				<set-header name="Ocp-Apim-Subscription-Key" exists-action="override">
					<value>@(context.Request.Url.Query.GetValueOrDefault("api_key", ""))</value>
				</set-header>
				<!-- 3. (Optional) remove api_key from query before sending to backend -->
				<set-query-parameter name="api_key" exists-action="delete" />
			</when>
		</choose>
		<validate-azure-ad-token tenant-id="tenant-id xxxxxxxx" header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
			<client-application-ids>
				<application-id>xxxxxxxxxxxxxxxxxxxxxx</application-id>
			</client-application-ids>
		</validate-azure-ad-token>
	</inbound>
	<!-- Control if and how the requests are forwarded to services  -->
	<backend>
		<base />
	</backend>
	<!-- Customize the responses -->
	<outbound>
		<base />
	</outbound>
	<!-- Handle exceptions and customize error responses  -->
	<on-error>
		<base />
	</on-error>
</policies>
```

8. Go to "https://ai.azure.com".
9. Find your Microsoft Foundry where the agent was created. Use the new Microsoft Foundry interface. You'll find the Microsoft Foundry project selector in the upper left corner.
10. Go to the "Build" tab - you'll find this option in the upper right corner.
11. Click on "Agents", then select "Agent-Insurance".
12. You can test the agent by typing in the chat window "List available insurance policies?". Information should appear asking whether you accept executing the "getPolicies" query. This time API Management should display the data.

---

## 12. Integration with Knowledge Base

### 12.1 Configuring Azure Database for PostgreSQL Flexible Server

1. If you don't already have an Azure Database for PostgreSQL flexible server resource, create one:
    - Search for "Azure Database for PostgreSQL flexible server" in Azure Portal
    - Click "+ Create"
    - Fill out the form and create the resource (Note! Authentication method: PostgreSQL and Microsoft Entra authentication. Create a user and save their password.)
2. After creating the resource, open it in the portal.
3. Go to the "Settings" -> "Server parameters" option.
4. On the "All" tab, for the "azure.extensions" parameter, select: AZURE_AI, PG_DISKANN, and VECTOR.
5. Make sure that in the "Settings" -> "Networking" option, there is a firewall rule allowing traffic from your IP address - necessary for connecting to the database in the next step.
6. Use Visual Studio Code with the PostgreSQL extension or pgAdmin (https://www.pgadmin.org/download/) to connect to the database. Connection parameters: server address, database name, user, and password are available in the resource view in the portal.

### 12.2 Data Population, Embedding, DiskANN Index Setup

1. Use the default "postgres" database.
2. In the "public" schema, create a new "policies" table using the script below.

```sql
DROP TABLE IF EXISTS policies;

CREATE TABLE IF NOT EXISTS policies (
    polisa_id    TEXT PRIMARY KEY,
    rodzaj_polisy TEXT NOT NULL,
    pakiet       TEXT,
    cena         NUMERIC(10,2) NOT NULL,
    opis         TEXT
);
```

3. Populate the newly created table with data:

```sql
INSERT INTO policies (polisa_id, rodzaj_polisy, pakiet, cena, opis)
VALUES
  ('123456', 'health', 'premium', 100, 'Premium health insurance.'),
  ('123457', 'auto', 'standard', 75, 'Basic car insurance.'),
  ('123458', 'travel', 'premium', 120, 'Comprehensive travel insurance with baggage protection and assistance.'),
  ('123459', 'home', 'standard', 90, 'Basic home insurance against random events.'),
  ('123460', 'life', 'premium', 150, 'Life insurance with high sum insured and additional benefits.'),
  ('123461', 'liability', 'standard', 60, 'Mandatory third-party liability insurance for drivers.'),
  ('123462', 'business', 'premium', 200, 'Business insurance covering property and civil liability.'),
  ('123463', 'bicycle', 'standard', 40, 'Bicycle insurance against theft and damage.')
  ;
```

4. Enable the AZURE_AI, PG_DISKANN, and VECTOR extensions:

```sql
CREATE EXTENSION IF NOT EXISTS azure_ai;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_diskann;
```

5. Configure connection parameters with OpenAI. We will use the model to create embeddings (Note! Make sure you have the "text-embedding-ada-002" model deployed in Microsoft Foundry):

```sql
 SELECT azure_ai.set_setting('azure_openai.auth_type', 'managed-identity');
SELECT azure_ai.set_setting('azure_openai.endpoint', '<endpoint>');
```

6. In the "policies" table, add an "embedding" column of vector type:

```sql
ALTER TABLE policies ADD COLUMN embedding vector(1536);
```

7. Build embeddings for data in the "policies" table:

```sql
WITH po AS (
    SELECT po.polisa_id
    FROM
        policies po
    WHERE
        po.embedding is null
        LIMIT 500 --limit to avoid exceeding request limits; if there are more than 500 records, execute the code multiple times
)
UPDATE
    policies p
SET
    embedding = azure_openai.create_embeddings('text-embedding-ada-002', p.rodzaj_polisy||' '||p.pakiet||' '||p.cena||' '||p.opis)
FROM
    po
WHERE
    p.polisa_id = po.polisa_id;
```

8. Build a DiskANN index on the "policies" table:

```sql
CREATE INDEX ON policies USING diskann (embedding vector_cosine_ops);
```

9. Test the vector search functionality:

```sql
SELECT
    p.*
FROM
    policies p
ORDER BY
    p.embedding <#> azure_openai.create_embeddings('text-embedding-ada-002', 'Car insurance policy')::vector
LIMIT 1;
```

### 12.3 Creating Vector Search Interface in Azure Function

1. If you don't already have an Azure Function resource, create one:
    - Search for "Azure Function" in Azure Portal
    - Click "+ Create"
    - Fill out the form and create the resource (Runtime: Python)
2. Using the Azure Functions extension in Visual Studio Code, create a new project (HTTP Triggered).
3. If needed, use the function code included in the repository.
4. Define a function that establishes a database connection:

```python
def _get_db_conn():
    """Create and return a new psycopg2 connection using env vars."""
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=int(os.getenv("PG_PORT", "5432")),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
    )
```

5. Define a function that performs vector search:

```python
def vector_search(
    query: str,
    table: str = "policies",
    id_column: str = "polisa_id",
    content_column: str = "opis",
) -> List[Dict]:
    """Perform a vector similarity search against an Azure PostgreSQL DB with `pgvector`.

    - `query`: text to search for. 
    - Returns a list of dicts with `id`, `content`.
    """
    conn = _get_db_conn()
    try:
        with conn.cursor() as cur:
            q = sql.SQL(
                "SELECT {id_col}, {content_col} "
                "FROM {table} "
                "ORDER BY embedding <#> azure_openai.create_embeddings('text-embedding-ada-002', {query})::vector "
                "LIMIT 1"
            ).format(
                id_col=sql.Identifier(id_column),
                content_col=sql.Identifier(content_column),
                query=sql.Literal(query),
                table=sql.Identifier(table),
            )

            cur.execute(q)
            rows = cur.fetchall()

            results = []
            for r in rows:
                results.append({"id": r[0], "content": r[1]})

            return results
    finally:
        conn.close()
```

6. And HTTP request handling:

```python
@app.route(route="get_policies", methods=("GET","POST"))
def get_policies(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        params = req.get_json()
    except Exception:
        params = {}

    query = req.params.get("q") or req.params.get("query") or params.get("q") or params.get("query")
    if not query:
        return func.HttpResponse("Missing 'query' parameter", status_code=400)
    
    try:
        results = vector_search(query)
    except Exception as e:
        logging.exception("vector_search failed")
        return func.HttpResponse(str(e), status_code=500)

    return func.HttpResponse(json.dumps(results), mimetype="application/json", status_code=200)
```

7. Note the required modules:

```python
azure-functions
psycopg2-binary
```

8. Deploy the code to the Azure Function resource.
9. Find and open the Azure Function resource in the portal.
10. In "Settings" -> "Environment variables", on the "App settings" tab, create settings:
    - PG_HOST
    - PG_PORT (default 5432)
    - PG_DATABASE
    - PG_USER
    - PG_PASSWORD

11. Test the function in "Overview" -> "Functions" -> (function name) -> "Code+Test" -> "Test/Run" option. Provide the "query" request parameter by entering e.g., "car insurance policy". Execution should return a result and HTTP 200.

### 12.4 Creating API

Perform similarly as in steps 1.4, 1.5, pointing to the endpoint of the created function.

### 12.5 Exposing API as MCP

Perform similarly as in section 11.

---

## 13. [Additional Tasks - Outside APIM] Data Agent in Microsoft Fabric

### 13.1 Configuring Microsoft Fabric

1. If you don't already have a Microsoft Fabric (Fabric Capacity) resource, create one:
    - Search for "Microsoft Fabric" in Azure Portal
    - Click "+ Create"
    - Fill out the form and create the resource (SKU: F2)
2. Go to the resource page in the portal. If Capacity is disabled, click "Resume".
3. Go to Microsoft Fabric in a separate browser tab (https://app.fabric.microsoft.com/).
4. Create a new workspace "Workspaces" -> "New workspace". In the "Advanced" tab, select "Fabric capacity".

### 13.2 PostgreSQL Mirroring Configuration

1. Go to the Azure Database for PostgreSQL resource page.
2. Go to the "Fabric mirroring" tab and click "Get started".
3. From the list of available databases, select "postgres" and then click "Prepare".
4. The resource will change its configuration to enable mirroring to Microsoft Fabric. During this time, the server may restart. After the process is complete, the "Fabric mirroring" tab will display the information "Server readiness": "Server is ready for mirroring".
5. Go to Microsoft Fabric, to the created workspace.
6. Click "New item" and from the list of objects select "Mirrored Azure Database for PostgreSQL (preview)".
7. In the next dialog window, click the connector name "Azure Database for PostgreSQL".
8. Provide connection parameters.
9. In the "Choose data" dialog, select the table ("public.policies") for replication. Ignore warnings about incompatible vector type.
10. Click "Connect", then name the new object. Click "Create mirrored database".
11. After a moment, a "Mirrored database" object will be created. Open it and verify that replication is working correctly (synchronized records status).

### 13.3 Creating Data Agent in Microsoft Fabric

1. In the workspace, click "New item" and select "Data agent (preview)". Provide the object name, click "Create".
2. In the agent dialog, in the "Explorer" tab, click "+ Data source" and select the created "Mirrored database". Click "Add".
3. In the "Explorer" tab, select the "policies" table as the data source for the agent.
4. Click the "Agent instructions" option.
5. In the new window, provide instructions for the agent (Markdown):

```txt

# Microsoft Fabric Data Agent – Insurance Advisor (Instructions)

## 0) Agent Role & Objective
You are the "Insurance Advisor" for our organization. 
Your job is to: (a) understand a customer's profile and needs; (b) search governed policy data; 
(c) recommend one or more suitable policies with clear reasoning; (d) return a concise, structured answer that an advisor can share with a customer.

Always respect security trimming and only query data sources the end user is permitted to access.

---

## 1) Data Sources & Preferred Routing
Use these data sources in order of preference:

1. Table `policies`:
   - Use for raw policy metadata.

---

## 2) Canonical Schema Notes (for NL→SQL)
- `policies(polisa_id, rodzaj_polisy, pakiet, cena, opis)`
- `premium_rates(rodzaj_polisy, pakiet)`
- `eligibility_rules(rodzaj_polisy)`

Use exact column names; prefer filters on `rodzaj_polisy` and `pakiet`. 
When joining, key is `rodzaj_polisy` (and `pakiet` where applicable).

---

## 3) Business Rules for Recommendations
Apply these rules before proposing results:

A. Eligibility (hard filters)
- Health ("zdrowotna"): age ≥ 18; if pre‑existing conditions flagged, include riders in coverage_options.
- Auto ("samochodowa"): requires `requires_vehicle = true`; check region_allow.
- Travel ("turystyczna"): if travel_frequency ≥ 2 trips/quarter → prefer "premium" pack; else "standard".
- Home ("mieszkaniowa"): requires property ownership; exclude high‑risk flood zones unless add‑on available.
- Life ("życie"): age ≤ 70 for standard; >70 → show "senior" variants if present.


---

## 4) Output Format (strict)
Return **only** the following JSON block in a fenced code block, plus a one‑paragraph summary above it:

Summary: 1–2 sentences explaining why the top policy is a fit, in plain language.
```
```json
{
  "top_recommendation": {
    "polisa_id": "<string>",
    "rodzaj_polisy": "<string>",
    "pakiet": "<string>"
  },
  "alternatives": [
    { "polisa_id":"...", "pakiet":"..." },
    { "polisa_id":"...", "pakiet":"..." }
  ],
  
}
```

6. Test the agent in the "Test the agent's responses" window, e.g., "looking for car insurance policy".
7. Publish the agent by clicking "Publish".

### 13.4 Exposing Data Agent as MCP for Microsoft Foundry

1. In the Microsoft Foundry portal (https://ai.azure.com) in New Foundry, create a new agent by clicking "Start building" -> "Create agent".
2. Give it a name, e.g., "agent-policies".
3. In the "Tools" tab, click "Add" and then "Add a new tool".
4. Select "Fabric Data Agent" and then "Add Tool".
5. In the connection configuration dialog, provide the Workspace ID and Artifact ID, available to read in Microsoft Fabric in the address bar on the page with the created Data Agent: https://app.fabric.microsoft.com/groups/<workspace-id>/aiskills/<artifact-id>?experience=fabric-developer
6. Click "Connect".
7. In the "Instructions" window, provide instructions for the agent:

```txt
You are the "Insurance Advisor" for our organization. 
Your job is to: (a) understand a customer's profile and needs; (b) search governed policy data; 
(c) recommend one or more suitable policies with clear reasoning; (d) return a concise, structured answer that an advisor can share with a customer. Make sure that you always use the tools to provide policy data.
```

8. Save changes and test the agent. In the chat window in "Debug", you should see a reference to Tool Fabric Data Agent.

---

## Summary

Congratulations! You have created a complete API interface using Azure API Management that:

- Provides information about insurance policies
- Integrates with Azure OpenAI Service
- Is secured by API keys and OAuth 2.0
- Controls traffic using call limits
- Limits tokens for AI queries
- Transforms and anonymizes data
- Integrates with a knowledge base in Azure Database for PostgreSQL and uses vector search
- Is monitored in Application Insights
