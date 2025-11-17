.PHONY: help build run dev clean test create-endpoint rollback list-endpoints clean-registry

help:
	@echo "📚 Go API Boilerplate - Code Generation Framework"
	@echo "=================================================="
	@echo ""
	@echo "🚀 ENDPOINT GENERATION COMMANDS"
	@echo "================================"
	@echo "Usage: make create-endpoint NAME=[name] METHODS=[methods]"
	@echo ""
	@echo "Examples:"
	@echo "  make create-endpoint NAME=roles METHODS=crdu        # Full CRUD"
	@echo "  make create-endpoint NAME=dashboard METHODS=r       # Read-only"
	@echo "  make create-endpoint NAME=products METHODS=cr       # Create & Read"
	@echo "  make create-endpoint NAME=posts METHODS=cru         # Create, Read, Update"
	@echo ""
	@echo "Operations:"
	@echo "  c - Create (POST)"
	@echo "  r - Read (GET all + GET by id)"
	@echo "  u - Update (PUT)"
	@echo "  d - Delete (DELETE)"
	@echo ""
	@echo "REGISTRY & MANAGEMENT"
	@echo "===================="
	@echo "  make list-endpoints     # List all generated endpoints"
	@echo "  make rollback NAME=[name]  # Rollback a generated endpoint"
	@echo "  make clean-registry     # Remove orphaned registry entries"
	@echo ""
	@echo "🔨 BUILD & RUN COMMANDS"
	@echo "======================"
	@echo "  make build              # Build the application"
	@echo "  make run                # Run the application"
	@echo "  make dev                # Run with hot-reload (requires air)"
	@echo "  make test               # Run tests"
	@echo "  make clean              # Clean build artifacts"
	@echo ""

create-endpoint:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Error: NAME parameter is required"; \
		echo "Usage: make create-endpoint NAME=[name] METHODS=[methods]"; \
		echo "Example: make create-endpoint NAME=roles METHODS=crdu"; \
		exit 1; \
	fi
	@if [ -z "$(METHODS)" ]; then \
		echo "❌ Error: METHODS parameter is required"; \
		echo "Usage: make create-endpoint NAME=[name] METHODS=[methods]"; \
		echo "Valid methods: c, r, u, d (can combine: crdu, cr, etc)"; \
		exit 1; \
	fi
	@chmod +x scripts/generate-endpoint.sh
	@bash scripts/generate-endpoint.sh "$(NAME)" "$(METHODS)"

rollback:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Error: NAME parameter is required"; \
		echo "Usage: make rollback NAME=[name]"; \
		echo "Example: make rollback NAME=roles"; \
		exit 1; \
	fi
	@chmod +x scripts/rollback-endpoint.sh
	@bash scripts/rollback-endpoint.sh "$(NAME)"

list-endpoints:
	@chmod +x scripts/list-endpoints.sh
	@bash scripts/list-endpoints.sh

clean-registry:
	@echo "🧹 Cleaning orphaned registry entries..."
	@chmod +x scripts/rollback-endpoint.sh
	@if [ -f "scripts/.generated_endpoints" ]; then \
		while IFS= read -r endpoint; do \
			if [ -z "$$endpoint" ]; then continue; fi; \
			if [ ! -f "models/$${endpoint}.go" ] || [ ! -f "controllers/$${endpoint}.go" ]; then \
				sed -i "/^$${endpoint}$$/d" scripts/.generated_endpoints; \
				echo "✓ Removed orphaned: $$endpoint"; \
			fi; \
		done < scripts/.generated_endpoints; \
		echo "✅ Registry cleaned"; \
	else \
		echo "ℹ Registry file not found"; \
	fi

build:
	@echo "🔨 Building Go API..."
	@go build -o bin/api cmd/main.go
	@echo "✅ Build complete"

run: build
	@echo "▶️  Running API..."
	@./bin/api

dev:
	@echo "🔄 Starting development server with hot-reload..."
	@which air > /dev/null || (echo "📦 Installing air..." && go install github.com/cosmtrek/air@latest)
	@air

test:
	@echo "🧪 Running tests..."
	@go test ./... -v

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf bin/
	@go clean
	@echo "✅ Clean complete"
