package migrations

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"gorm.io/gorm"
)

// RunMigrations executes all SQL migration files in order
func RunMigrations(db *gorm.DB) error {
	migrationsDir := "database/migrations"

	// Get all .sql files
	files, err := filepath.Glob(filepath.Join(migrationsDir, "*.sql"))
	if err != nil {
		return fmt.Errorf("failed to read migrations: %w", err)
	}

	// Sort files by name (timestamp-based)
	sort.Strings(files)

	// Execute each migration
	for _, file := range files {
		// Skip the init.go file itself
		if filepath.Ext(file) != ".sql" {
			continue
		}

		content, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("failed to read migration file %s: %w", file, err)
		}

		if err := db.Exec(string(content)).Error; err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", file, err)
		}

		fmt.Printf("✓ Executed migration: %s\n", filepath.Base(file))
	}

	return nil
}
