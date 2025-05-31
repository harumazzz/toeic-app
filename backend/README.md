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
- Database backup and restore functionality

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
- `POST /api/auth/login` - Login with email and password
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/logout` - Logout and invalidate tokens
- `POST /api/auth/refresh-token` - Refresh access token using refresh token

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

## Database Backup and Restore

### Via API (Admin only)

The application provides a REST API for database backup and restore operations:

- `POST /api/v1/admin/backups` - Create a new backup
- `GET /api/v1/admin/backups` - List all backups
- `GET /api/v1/admin/backups/download/{filename}` - Download a backup
- `DELETE /api/v1/admin/backups/{filename}` - Delete a backup
- `POST /api/v1/admin/backups/restore` - Restore from a backup
- `POST /api/v1/admin/backups/upload` - Upload a backup file

These endpoints are accessible only to admin users and require authentication.

### Via Makefile

For convenience, you can use the following Makefile commands:

```bash
# Create a backup
make backup

# List all backups
make backup-list

# Restore from a backup
make restore file=backups/your_backup.sql
```

### Requirements

The backup/restore functionality requires PostgreSQL client tools (`pg_dump` and `psql`) to be installed on the server:

- For Windows: Install PostgreSQL and make sure the bin directory is in your PATH
- For Linux: `apt-get install postgresql-client`
- For macOS: `brew install postgresql`

## Docker command
- ` docker exec -it toeic_postgres psql -U root -d toeic_db`