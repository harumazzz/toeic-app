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

backup:
	@echo "Creating database backup..."
	docker exec -it toeic_postgres pg_dump -U root -d toeic_db --clean --if-exists --no-owner --no-privileges -f /tmp/backup.sql
	docker cp toeic_postgres:/tmp/backup.sql ./backups/toeic_db_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created: ./backups/toeic_db_$(shell date +%Y%m%d_%H%M%S).sql"

restore:
	@if [ -z "$(file)" ]; then \
		echo "Usage: make restore file=backups/your_backup.sql"; \
		exit 1; \
	fi
	@echo "Restoring database from $(file)..."
	docker cp $(file) toeic_postgres:/tmp/restore.sql
	docker exec -it toeic_postgres psql -U root -d toeic_db -f /tmp/restore.sql
	@echo "Database restored from $(file)"

backup-list:
	@echo "Available backup files:"
	@ls -lh backups/*.sql 2>/dev/null || echo "No backup files found."

.PHONY: postgres createdb dropdb migrateup migratedown sqlc install-tools test swagger run run-with-logs backup restore backup-list
