package models

import "gorm.io/gorm"

func InitModels(db *gorm.DB) {
	db.AutoMigrate(&User{})
}
