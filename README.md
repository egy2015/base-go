# Go REST API Boilerplate

A production-ready RESTful API built with Go using Gin Gonic, GORM, PostgreSQL, Redis, and RabbitMQ.

## Technology Stack

- **Web Framework**: Gin Gonic
- **ORM**: GORM
- **Database**: PostgreSQL
- **Cache**: Redis
- **Message Queue**: RabbitMQ
- **Authentication**: JWT (JSON Web Token)
- **Go Version**: 1.22+

## Features

- ✅ JWT-based authentication
- ✅ User registration and login
- ✅ Protected endpoints
- ✅ Asynchronous message processing via RabbitMQ
- ✅ Database seeding on startup
- ✅ Health check endpoint
- ✅ Docker Compose setup for all services
- ✅ Comprehensive error handling

## Project Structure

```
├── cmd/
│   └── main.go              # Application entry point
├── config/
│   └── config.go            # Configuration management
├── controllers/
│   ├── auth.go              # Authentication endpoints
│   ├── user.go              # User profile endpoint
│   ├── health.go            # Health check endpoint
│   └── sync.go              # Sync trigger endpoint
├── database/
│   ├── connection.go        # Database connection
│   └── migrations.go        # Database migrations
├── middleware/
│   └── jwt.go               # JWT authentication middleware
├── models/
│   └── user.go              # User model
├── messaging/
│   └── rabbitmq.go          # RabbitMQ integration
├── routes/
│   └── routes.go            # Route setup
├── seeders/
│   └── seeder.go            # Database seeding
├── docker-compose.yml       # Docker Compose configuration
├── Dockerfile               # Docker image definition
├── go.mod                   # Go modules file
├── go.sum                   # Dependencies lock file
└── .env.example             # Environment variables template
```


## Prerequisites

- Docker & Docker Compose
- Go 1.22+ (for local development)

## Quick Start

### Using Docker Compose

1. **Clone the repository and setup environment variables:**

   ```bash
   cp .env.example .env
   ```

2. **Build and start all services:**

   ```bash
   docker-compose up -d
   ```

   This will start:
   - PostgreSQL on port 5432
   - Redis on port 6379
   - RabbitMQ on port 5672 (API) and 15672 (Management UI)
   - Go API on port 8080

3. **Verify the API is running:**

   ```bash
   curl http://localhost:8080/api/v1/ping
   ```

   Expected response:
   ```json
   {
     "status": "healthy",
     "message": "API is running"
   }
   ```

### Local Development

1. **Install dependencies:**

   ```bash
   go mod download
   ```

2. **Start external services using Docker Compose (without the API):**

   ```bash
   docker-compose up -d postgres redis rabbitmq
   ```

3. **Run the application:**

   ```bash
   go run cmd/main.go
   ```

## API Endpoints

### Health Check

**GET** `/api/v1/ping`

Returns API health status.

```bash
curl http://localhost:8080/api/v1/ping
```

**Response (200):**
```json
{
  "status": "healthy",
  "message": "API is running"
}
```

### Authentication

#### Register

**POST** `/api/v1/register`

Create a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (201):**
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

#### Login

**POST** `/api/v1/login`

Authenticate and receive a JWT token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response (200):**
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

### Protected Endpoints

#### Get User Profile

**GET** `/api/v1/user/profile`

Retrieve the authenticated user's profile.

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "user"
}
```

#### Trigger Sync

**POST** `/api/v1/sync/trigger`

Publish a sync message to RabbitMQ for asynchronous processing.

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Request Body:**
```json
{
  "data_type": "user_data",
  "data": {
    "field1": "value1",
    "field2": "value2"
  }
}
```

**Response (202):**
```json
{
  "message": "Sync triggered successfully",
  "id": "1234567890"
}
```

## Default Credentials

After seeding, the following credentials are available:

**Admin Account:**
- Email: `admin@example.com`
- Password: `admin123`

**Dummy Users:**
- Email: `user1@example.com` / Password: `user123`
- Email: `user2@example.com` / Password: `user456`

## Accessing External Services

### PostgreSQL

```bash
docker-compose exec postgres psql -U postgres -d api_db
```

### Redis CLI

```bash
docker-compose exec redis redis-cli
```

### RabbitMQ Management UI

Open your browser and navigate to: **http://localhost:15672**

- Default Username: `guest`
- Default Password: `guest`

### View Logs

```bash
docker-compose logs -f api
```

## Environment Variables

Create a `.env` file based on `.env.example`:

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

### Important Security Notes

- Change `JWT_SECRET` in production
- Use strong database passwords in production
- Enable SSL/TLS for PostgreSQL in production
- Configure proper RabbitMQ authentication in production
- Use environment-specific configurations

## Development

### Running Tests

```bash
go test ./...
```

### Building for Production

```bash
docker build -t your-registry/api:latest .
docker push your-registry/api:latest
```

### Database Migrations

Migrations are automatically run on startup via `RunMigrations()` in `database/migrations.go`.

## Troubleshooting

### Connection refused errors

Ensure all services are running and healthy:

```bash
docker-compose ps
```

### Database migration errors

Check that PostgreSQL is running and the credentials are correct:

```bash
docker-compose logs postgres
```

### RabbitMQ connection issues

Verify RabbitMQ is running and the connection URL is correct:

```bash
docker-compose logs rabbitmq
```

## License

MIT
