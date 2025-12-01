# API Documentation

This project uses OpenAPI 3.0 specification for API documentation. The Swagger definition is located in `docs/swagger.yaml`.

## Viewing the Documentation

### Option 1: Swagger UI (Recommended)

1. **Using Online Editor**: Visit [Swagger Editor](https://editor.swagger.io) and paste the contents of `docs/swagger.yaml`

2. **Local Swagger UI with Docker**:
   ```bash
   docker run -p 8000:8080 -e SWAGGER_JSON=/api/swagger.yaml \
     -v $(pwd)/docs/swagger.yaml:/api/swagger.yaml \
     swaggerapi/swagger-ui
   ```
   Then access at `http://localhost:8000`

### Option 2: Integrate Swagger UI into Your API

Add [swaggo/gin-swagger](https://github.com/swaggo/gin-swagger) to serve docs from your API:

```bash
go get github.com/swaggo/gin-swagger
go get github.com/swaggo/files
```

Then add to your main.go:

```go
import (
    ginSwagger "github.com/swaggo/gin-swagger"
    "github.com/swaggo/files"
)

// In SetupRoutes function
router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
```

## API Structure

The API uses semantic versioning in the URL path (`/api/v1`).

### Authentication

Most endpoints require JWT authentication via the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

### Response Format

All responses follow this convention:

**Success Response**:
```json
{
  "data": {...}
}
```

**Error Response**:
```json
{
  "error": "error message"
}
```

## Common Status Codes

- `200 OK` - Request succeeded
- `201 Created` - Resource created successfully
- `202 Accepted` - Request accepted for async processing
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing or invalid authentication
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `500 Internal Server Error` - Server error

## Generating Endpoints

When you generate new endpoints using the framework, update this Swagger file with the new paths and schemas:

```bash
make create-endpoint NAME=products METHODS=c,r,u,d
```

Then add the corresponding routes to `docs/swagger.yaml`.

If you don't know about swagger, you can learn it [here](https://swagger.io/docs/).