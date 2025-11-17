# Go REST API Boilerplate

A production-ready RESTful API framework built with Go using Gin Gonic, GORM, PostgreSQL, Redis, and RabbitMQ. Includes a powerful code generation system for rapid endpoint scaffolding.

## 🎯 Features

- ✅ **JWT-based authentication** with register/login
- ✅ **Code generation framework** for rapid endpoint scaffolding
- ✅ **Full CRUD operations** generation with one command
- ✅ **Protected endpoints** with JWT middleware
- ✅ **Asynchronous messaging** via RabbitMQ
- ✅ **Database seeding** on startup
- ✅ **Health monitoring** endpoints
- ✅ **Docker Compose** setup for all services
- ✅ **Production-ready** error handling & logging

## 🛠 Technology Stack

- **Framework**: Gin Gonic
- **ORM**: GORM
- **Database**: PostgreSQL
- **Cache**: Redis
- **Queue**: RabbitMQ
- **Auth**: JWT
- **Go Version**: 1.22+

## 📂 Project Structure

```
├── cmd/
│   └── main.go                      # Entry point
├── config/
│   └── config.go                    # Configuration
├── controllers/
│   ├── auth.go                      # Authentication
│   ├── user.go                      # User management
│   ├── health.go                    # Health checks
│   └── sync.go                      # Sync operations
├── database/
│   ├── connection.go                # DB connection
│   ├── migrations.go                # Migrations
│   └── migrations/                  # SQL migration files
├── middleware/
│   └── jwt.go                       # JWT middleware
├── models/
│   └── user.go                      # Data models
├── messaging/
│   └── rabbitmq.go                  # Message queue
├── routes/
│   └── routes.go                    # Route definitions
├── scripts/
│   ├── generate-endpoint.sh         # Generator
│   ├── rollback-endpoint.sh         # Rollback tool
│   ├── list-endpoints.sh            # List endpoints
│   └── .generated_endpoints         # Registry
├── seeders/
│   └── seeder.go                    # Database seeding
├── docker-compose.yml               # Services
├── Dockerfile                       # Image definition
├── Makefile                         # Task automation
└── .env.example                     # Env template
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Go 1.22+ (local development)

### Using Docker Compose

```bash
# Setup environment
cp .env.example .env

# Start all services
docker-compose up -d

# Verify API is running
curl http://localhost:8080/api/v1/ping
```

### Local Development

```bash
# Download dependencies
go mod download

# Start external services only
docker-compose up -d postgres redis rabbitmq

# Run application
go run cmd/main.go
```

## 🎨 Code Generation Framework

The framework provides powerful commands to generate complete endpoints with one command.

### Generate Full CRUD Endpoint

```bash
make create-endpoint NAME=roles METHODS=crdu
```

**Generated files:**
- `models/roles.go` - Data model with GORM struct
- `controllers/roles.go` - All CRUD handlers
- `scripts/roles_routes.txt` - Routes to add to `routes/routes.go`
- `database/migrations/[timestamp]_create_roles_table.sql` - Database schema

**Result:** 4 API endpoints ready to use
```
POST   /api/v1/roles              # Create
GET    /api/v1/roles              # Read all
GET    /api/v1/roles/:id          # Read one
PUT    /api/v1/roles/:id          # Update
DELETE /api/v1/roles/:id          # Delete
```

### Generate Read-Only Endpoint

```bash
make create-endpoint NAME=dashboard METHODS=r
```

**Result:** 2 read-only endpoints
```
GET    /api/v1/dashboard          # Get all
GET    /api/v1/dashboard/:id      # Get one
```

### Generate Custom Operations

```bash
make create-endpoint NAME=products METHODS=cru   # Create, Read, Update (no Delete)
make create-endpoint NAME=reports METHODS=cr     # Create & Read only
make create-endpoint NAME=analytics METHODS=r    # Read-only
```

### Integration Steps

After generation:

1. **Update model fields** in `models/[name].go`
   - Change `Name` field to your actual fields
   - Add validation tags as needed

2. **Add routes** - Copy routes from `scripts/[name]_routes.txt` to `routes/routes.go`
   ```go
   // Example from generated routes file
   protectedRoutes.GET("/roles", controllers.GetAll_Roles(db))
   protectedRoutes.GET("/roles/:id", controllers.GetByID_Roles(db))
   protectedRoutes.POST("/roles", controllers.Create_Roles(db))
   protectedRoutes.PUT("/roles/:id", controllers.Update_Roles(db))
   protectedRoutes.DELETE("/roles/:id", controllers.Delete_Roles(db))
   ```

3. **Review migration** in `database/migrations/[timestamp]_create_[name]_table.sql`
   - Customize columns and constraints
   - Migrations run automatically on startup

### Management Commands

```bash
# List all generated endpoints
make list-endpoints

# Rollback an endpoint (delete all related files)
make rollback NAME=roles

# Clean orphaned registry entries
make clean-registry
```

## 📡 API Endpoints

### Health Check

```bash
curl http://localhost:8080/api/v1/ping
```

Response:
```json
{
  "status": "healthy",
  "message": "API is running"
}
```

### Authentication

#### Register
```bash
curl -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

#### Login
```bash
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "user"
  }
}
```

### Protected Endpoint (requires JWT token)

```bash
curl -X GET http://localhost:8080/api/v1/user/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🔐 Default Credentials

After seeding:

```
Admin Account:
  Email: admin@example.com
  Password: admin123

Test Accounts:
  Email: user1@example.com / Password: user123
  Email: user2@example.com / Password: user456
```

## 🛢 Database Access

### PostgreSQL
```bash
docker-compose exec postgres psql -U postgres -d api_db
```

### Redis CLI
```bash
docker-compose exec redis redis-cli
```

### RabbitMQ Management UI
Open: **http://localhost:15672**
- Username: `guest`
- Password: `guest`

### View Logs
```bash
docker-compose logs -f api
```

## ⚙️ Environment Variables

Create `.env` from `.env.example`:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=api_db

REDIS_ADDR=localhost:6379

RABBITMQ_URL=amqp://guest:guest@localhost:5672/

JWT_SECRET=your-secret-key-change-in-production

ENVIRONMENT=development
PORT=8080
```

### Security Notes (Production)
- Change `JWT_SECRET` to a strong random value
- Use strong database passwords
- Enable SSL/TLS for PostgreSQL
- Configure secure RabbitMQ authentication
- Use separate env configurations per environment

## 🧪 Testing

```bash
# Run all tests
go test ./...

# Run with verbose output
go test ./... -v

# Run specific test
go test ./controllers -v
```

## 🐳 Docker

### Build for Production
```bash
docker build -t your-registry/api:latest .
docker push your-registry/api:latest
```

### Run Container
```bash
docker run -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e JWT_SECRET=your-secret \
  your-registry/api:latest
```

## 🔧 Makefile Commands

```bash
make help              # Show all available commands
make build             # Build binary
make run               # Build and run
make dev               # Run with hot-reload (requires air)
make test              # Run tests
make clean             # Remove build artifacts
```

## 🚨 Troubleshooting

### Connection Refused
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs [service-name]
```

### Database Errors
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d
```

### Generated Endpoints Not Working
1. Verify routes are added to `routes/routes.go`
2. Check model and controller files exist
3. Run `make list-endpoints` to verify registration
4. Restart the application

## 📚 Makefile Reference

| Command | Purpose |
|---------|---------|
| `make help` | Display all commands and usage |
| `make create-endpoint NAME=x METHODS=y` | Generate new endpoint |
| `make rollback NAME=x` | Remove generated endpoint |
| `make list-endpoints` | Show all generated endpoints |
| `make clean-registry` | Cleanup orphaned entries |
| `make build` | Compile application |
| `make run` | Build and run |
| `make dev` | Hot-reload development |
| `make test` | Run test suite |
| `make clean` | Clean artifacts |

## 📖 Additional Resources

- [Gin Documentation](https://gin-gonic.com/)
- [GORM Guide](https://gorm.io/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)

## 📄 License

MIT
