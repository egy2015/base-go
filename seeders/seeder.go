package seeders

import (
	"api/models"
	"log"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func SeedDatabase(db *gorm.DB) error {
	// Check if admin user already exists
	var adminUser models.User
	if err := db.Where("email = ?", "admin@example.com").First(&adminUser).Error; err == nil {
		log.Println("Database already seeded, skipping...")
		return nil
	}

	// Hash admin password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// Create admin user
	adminUser = models.User{
		Email:     "admin@example.com",
		Password:  string(hashedPassword),
		FirstName: "Admin",
		LastName:  "User",
		Role:      "admin",
	}

	if err := db.Create(&adminUser).Error; err != nil {
		return err
	}

	log.Println("Database seeded successfully")
	log.Println("Admin credentials: admin@example.com / admin123")

	// Create some dummy users
	dummyUsers := []models.User{
		{
			Email:     "user1@example.com",
			Password:  hashPassword("user123"),
			FirstName: "John",
			LastName:  "Doe",
			Role:      "user",
		},
		{
			Email:     "user2@example.com",
			Password:  hashPassword("user456"),
			FirstName: "Jane",
			LastName:  "Smith",
			Role:      "user",
		},
	}

	for _, user := range dummyUsers {
		if err := db.Create(&user).Error; err != nil {
			log.Printf("Failed to create dummy user: %v\n", err)
		}
	}

	log.Println("Dummy users created successfully")
	return nil
}

func hashPassword(password string) string {
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hashedPassword)
}
