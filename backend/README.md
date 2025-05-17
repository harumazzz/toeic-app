# TOEIC App Backend

This is a backend service for a TOEIC application using Go, PostgreSQL, and sqlc.

## Features

- RESTful API with Gin framework
- PostgreSQL database with SQLC for type-safe SQL queries
- JWT authentication with access and refresh tokens
- Swagger API documentation
- Password hashing with bcrypt
- Input validation using custom validators
- CORS support
- Health and metrics endpoints for monitoring

## Prerequisites

- Docker and Docker Compose
- Go 1.21 or higher
- Make (optional, for running commands from the Makefile)

## Setup

### Install Required Go Tools

```bash
go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
```

Or use the Makefile command:

```bash
make install-tools
```

### Start PostgreSQL

```bash
docker compose up -d
```

Or use the Makefile command:

```bash
make postgres
```

### Run Migrations

```bash
migrate -path db/migrations -database "postgresql://root:password@localhost:5432/toeic_db?sslmode=disable" -verbose up
```

Or use the Makefile command:

```bash
make migrateup
```

### Generate sqlc Code

```bash
sqlc generate
```

Or use the Makefile command:

```bash
make sqlc
```

### Generate API Documentation

```bash
swag init -g main.go -o ./docs
```

Or use the Makefile command:

```bash
make swagger
```

### Run the Application

```bash
go run main.go
```

## API Endpoints

### Authentication
- `POST /api/login` - Login with email and password
- `POST /api/refresh-token` - Refresh access token using refresh token

### Users
- `POST /api/v1/users` - Create a new user
- `GET /api/v1/users/me` - Get current user profile (authenticated)
- `GET /api/v1/users/:id` - Get user by ID (authenticated)
- `GET /api/v1/users` - List all users (authenticated)
- `PUT /api/v1/users/:id` - Update a user (authenticated)
- `DELETE /api/v1/users/:id` - Delete a user (authenticated)

### System
- `GET /health` - Health check endpoint
- `GET /metrics` - System metrics endpoint
- `GET /swagger/*any` - Swagger API documentation

## Database Access

- PostgreSQL is available at `localhost:5432`
- Username: `root`
- Password: `password`
- Database: `toeic_db`
- Adminer (database management tool) is available at `http://localhost:8080`

## Docker command
- ` docker exec -it toeic_postgres psql -U root -d toeic_db`