package routes

import (
	"api/config"
	"api/controllers"
	"api/middleware"
	"api/messaging"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRoutes(router *gin.Engine, db *gorm.DB, cfg *config.Config) {
	// Initialize RabbitMQ
	rmq, err := messaging.NewRabbitMQ(cfg.RabbitMQURL)
	if err != nil {
		panic("Failed to connect to RabbitMQ: " + err.Error())
	}

	// Setup RabbitMQ exchange and queues
	if err := rmq.DeclareExchange("sync_exchange", "direct"); err != nil {
		panic("Failed to declare exchange: " + err.Error())
	}

	if _, err := rmq.DeclareQueue("sync_queue"); err != nil {
		panic("Failed to declare queue: " + err.Error())
	}

	if err := rmq.BindQueue("sync_queue", "sync_exchange", "sync.trigger"); err != nil {
		panic("Failed to bind queue: " + err.Error())
	}

	// Health check
	router.GET("/api/v1/ping", controllers.HealthCheck)

	// Authentication routes (public)
	router.POST("/api/v1/register", controllers.Register(db, cfg.JWTSecret))
	router.POST("/api/v1/login", controllers.Login(db, cfg.JWTSecret))

	// Protected routes
	protectedRoutes := router.Group("/api/v1")
	protectedRoutes.Use(middleware.JWTAuthMiddleware(cfg.JWTSecret))
	{
		protectedRoutes.GET("/user/profile", controllers.GetUserProfile(db))
		protectedRoutes.POST("/sync/trigger", controllers.TriggerSync(rmq))
	}
}
