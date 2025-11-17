package controllers

import (
	"api/messaging"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type SyncTriggerRequest struct {
	DataType string            `json:"data_type" binding:"required"`
	Data     map[string]interface{} `json:"data" binding:"required"`
}

type SyncMessage struct {
	ID        string                 `json:"id"`
	DataType  string                 `json:"data_type"`
	Data      map[string]interface{} `json:"data"`
	Timestamp string                 `json:"timestamp"`
	UserID    uint                   `json:"user_id"`
}

func TriggerSync(rmq *messaging.RabbitMQ) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}

		var req SyncTriggerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Create sync message
		syncMsg := SyncMessage{
			ID:        generateID(),
			DataType:  req.DataType,
			Data:      req.Data,
			Timestamp: time.Now().UTC().Format(time.RFC3339),
			UserID:    userID.(uint),
		}

		// Marshal message
		msgBytes, err := json.Marshal(syncMsg)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to marshal message"})
			return
		}

		// Publish to RabbitMQ
		if err := rmq.PublishMessage("sync_exchange", "sync.trigger", msgBytes); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to publish message"})
			return
		}

		c.JSON(http.StatusAccepted, gin.H{
			"message": "Sync triggered successfully",
			"id":      syncMsg.ID,
		})
	}
}

func generateID() string {
	return time.Now().UnixNano() | 1<<63 // Simple ID generation, replace with UUID for production
}
