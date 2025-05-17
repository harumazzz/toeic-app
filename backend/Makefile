.PHONY: postgres createdb dropdb migrateup migratedown sqlc

postgres:
	docker compose up -d

createdb:
	docker exec -it toeic_postgres createdb --username=root --owner=root toeic_db

dropdb:
	docker exec -it toeic_postgres dropdb toeic_db

migrateup:
	migrate -path db/migrations -database "postgresql://root:password@localhost:5432/toeic_db?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migrations -database "postgresql://root:password@localhost:5432/toeic_db?sslmode=disable" -verbose down

sqlc:
	sqlc generate

install-tools:
	go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
	go install github.com/swaggo/swag/cmd/swag@latest

test:
	go test -v -cover ./...

swagger:
	swag init -g main.go -o ./docs

run:
	go run main.go

run-with-logs:
	powershell -ExecutionPolicy Bypass -File ./scripts/run_with_logs.ps1

.PHONY: postgres createdb dropdb migrateup migratedown sqlc install-tools test swagger run run-with-logs
