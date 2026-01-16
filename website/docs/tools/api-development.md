---
title: API Development Tools
sidebar_position: 4
---

# API Development Tools

VS Code extensions for API development, testing, and documentation. Test REST APIs and design OpenAPI specifications without leaving your editor.

## What Gets Installed

### VS Code Extensions

| Extension | Description |
|-----------|-------------|
| Thunder Client | Lightweight REST API client for testing endpoints |
| OpenAPI Editor | OpenAPI/Swagger editing, validation, and preview |

:::note
This tool installs VS Code extensions only - no CLI tools or packages.
:::

## Installation

Install via the interactive menu:

```bash
dev-setup
```

Or install directly:

```bash
.devcontainer/additions/install-tool-api-dev.sh
```

To uninstall:

```bash
.devcontainer/additions/install-tool-api-dev.sh --uninstall
```

## Thunder Client

Thunder Client is a lightweight alternative to Postman, built directly into VS Code.

### Getting Started

1. Open Thunder Client from the VS Code sidebar (lightning bolt icon)
2. Click **New Request**
3. Enter your API URL and select the HTTP method
4. Click **Send**

### Key Features

- **Collections**: Save and organize requests into collections
- **Environments**: Define variables for different environments (dev, staging, prod)
- **Variables**: Use `{{variable}}` syntax in URLs and headers
- **Authentication**: Support for Bearer tokens, Basic Auth, OAuth 2.0
- **Tests**: Write tests to validate responses

### Example Request

```
GET https://api.github.com/users/octocat

Headers:
  Accept: application/json
  User-Agent: MyApp
```

### Using Environment Variables

Create an environment with variables:

```json
{
  "baseUrl": "http://localhost:3000",
  "apiKey": "your-api-key"
}
```

Use in requests:

```
GET {{baseUrl}}/api/users
Authorization: Bearer {{apiKey}}
```

## OpenAPI Editor

Design, edit, and validate OpenAPI/Swagger specifications with real-time feedback.

### Getting Started

1. Create a new file with `.yaml` or `.json` extension
2. Start with the OpenAPI template
3. Get real-time validation as you type
4. Preview your API documentation

### Example OpenAPI Spec

```yaml
openapi: 3.0.3
info:
  title: My API
  version: 1.0.0
  description: A sample API

servers:
  - url: http://localhost:3000
    description: Development server

paths:
  /users:
    get:
      summary: List all users
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        email:
          type: string
          format: email
```

### Key Features

- **Syntax Validation**: Real-time error checking
- **Auto-completion**: Suggestions for OpenAPI keywords
- **Navigation**: Jump to schema definitions
- **Preview**: See rendered documentation
- **Security Audit**: Check for security issues

## Example Workflows

### API-First Development

1. **Design**: Create OpenAPI spec in `openapi.yaml`
2. **Validate**: Use OpenAPI Editor for real-time validation
3. **Implement**: Build API endpoints based on spec
4. **Test**: Use Thunder Client to test each endpoint
5. **Iterate**: Update spec and implementation as needed

### Testing an Existing API

1. Open Thunder Client
2. Create a new collection for the API
3. Add requests for each endpoint
4. Set up environments for dev/staging/prod
5. Save and share collection with team

### Generating Client Code

Once you have an OpenAPI spec, you can generate client code:

```bash
# Using OpenAPI Generator (install separately)
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g typescript-fetch \
  -o ./generated-client
```

## Tips and Best Practices

### Thunder Client

- Use collections to organize related requests
- Create separate environments for each deployment stage
- Add tests to validate response structure
- Export collections to share with teammates

### OpenAPI

- Start with a template and modify
- Use `$ref` to avoid duplication in schemas
- Include examples for better documentation
- Validate spec before sharing

## Documentation

- [Thunder Client Docs](https://www.thunderclient.com/docs)
- [OpenAPI Specification](https://www.openapis.org/)
- [OpenAPI Editor Extension](https://marketplace.visualstudio.com/items?itemName=42Crunch.vscode-openapi)
