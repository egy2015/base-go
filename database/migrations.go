package database

import (
	"api/models"

	"gorm.io/gorm"
)

func RunMigrations(db *gorm.DB) error {
	// Auto-migrate User model
	if err := db.AutoMigrate(&models.User{}); err != nil {
		return err
	}
	return nil
}
