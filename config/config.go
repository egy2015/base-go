package config

import (
	// "fmt"
	"os"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type Config struct {
	DBHost      string
	DBPort      string
	DBUser      string
	DBPassword  string
	DBName      string
	RedisAddr   string
	RabbitMQURL string
	JWTSecret   string
	Environment string
}

func LoadConfig() *Config {
	return &Config{
		DBHost:      getEnv("DB_HOST", ""),
		DBPort:      getEnv("DB_PORT", ""),
		DBUser:      getEnv("DB_USER", ""),
		DBPassword:  getEnv("DB_PASSWORD", ""),
		DBName:      getEnv("DB_NAME", ""),
		RedisAddr:   getEnv("REDIS_ADDR", ""),
		RabbitMQURL: getEnv("RABBITMQ_URL", ""),
		JWTSecret:   getEnv("JWT_SECRET", ""),
		Environment: getEnv("ENVIRONMENT", ""),
	}
}

func getEnv(key, defaultVal string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultVal
}

type Database struct {
	DB *gorm.DB
}

type Cache struct {
	Client *redis.Client
}
