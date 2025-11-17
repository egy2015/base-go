#!/bin/bash


# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arguments
RESOURCE_NAME="$1"
METHODS="$2"

# Validate resource name
if [ -z "$RESOURCE_NAME" ]; then
    echo -e "${RED}Error: Resource name is required${NC}"
    echo "Usage: $0 <resource_name> <methods>"
    exit 1
fi

if [ -z "$METHODS" ]; then
    echo -e "${RED}Error: Methods are required${NC}"
    echo "Usage: $0 <resource_name> <methods>"
    exit 1
fi

# Validate methods format
if ! [[ "$METHODS" =~ ^[crdu]+$ ]] && ! [[ "$METHODS" =~ ^[crdu,]+$ ]]; then
    echo -e "${RED}Error: Invalid methods format${NC}"
    echo "Valid methods: c (Create), r (Read), u (Update), d (Delete)"
    echo "Usage: c,r,u,d or crud (commas optional)"
    exit 1
fi

# Normalize methods (remove commas)
METHODS="${METHODS//,/}"

# Convert to various case formats for consistency
SNAKE_CASE=$(echo "$RESOURCE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_$//')
PASCAL_CASE=$(echo "$SNAKE_CASE" | sed 's/\b$$.$$/\U\1/g')
CAMEL_CASE=$(echo "$SNAKE_CASE" | sed 's/_$$[a-z]$$/\U\1/g')
PLURAL_SNAKE="${SNAKE_CASE}"
SINGULAR_SNAKE=$(echo "$SNAKE_CASE" | sed 's/s$//')

# Ensure registry directory exists
mkdir -p scripts
REGISTRY_FILE="scripts/.generated_endpoints"
touch "$REGISTRY_FILE"

# Check if already exists
if [ -f "models/${SNAKE_CASE}.go" ] || [ -f "controllers/${SNAKE_CASE}.go" ]; then
    echo -e "${YELLOW}⚠ Warning: Endpoint '${SNAKE_CASE}' already exists${NC}"
    read -p "Do you want to overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Generating endpoint for: ${PASCAL_CASE}${NC}"
echo -e "Methods: ${METHODS}"
echo ""

# Parse methods
HAS_CREATE=false
HAS_READ=false
HAS_UPDATE=false
HAS_DELETE=false

for (( i=0; i<${#METHODS}; i++ )); do
    method="${METHODS:$i:1}"
    case "$method" in
        c) HAS_CREATE=true ;;
        r) HAS_READ=true ;;
        u) HAS_UPDATE=true ;;
        d) HAS_DELETE=true ;;
    esac
done

# Generate Model
echo -e "${BLUE}→ Generating model...${NC}"
cat > "models/${SNAKE_CASE}.go" << 'MODEL_EOF'
package models

import (
	"time"

	"gorm.io/gorm"
)

// MODEL_NAME represents a MODEL_NAME record
type MODEL_NAME struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"not null;index" json:"name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`
}

// TableName specifies the table name
func (MODEL_NAME) TableName() string {
	return "PLURAL_SNAKE"
}
MODEL_EOF

# Replace placeholders
sed -i "s/MODEL_NAME/${PASCAL_CASE}/g" "models/${SNAKE_CASE}.go"
sed -i "s/PLURAL_SNAKE/${PLURAL_SNAKE}/g" "models/${SNAKE_CASE}.go"

echo -e "${GREEN}✓ Created: models/${SNAKE_CASE}.go${NC}"

# Generate Controller
echo -e "${BLUE}→ Generating controller...${NC}"
cat > "controllers/${SNAKE_CASE}.go" << 'CONTROLLER_EOF'
package controllers

import (
	"api/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// GetAll_PLURAL_PASCAL retrieves all items
func GetAll_PLURAL_PASCAL(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var items []models.MODEL_NAME
		if err := db.Find(&items).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch items"})
			return
		}
		c.JSON(http.StatusOK, items)
	}
}

// GetByID_PLURAL_PASCAL retrieves a single item by ID
func GetByID_PLURAL_PASCAL(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var item models.MODEL_NAME
		if err := db.First(&item, id).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}
		c.JSON(http.StatusOK, item)
	}
}

// Create_PLURAL_PASCAL creates a new item
func Create_PLURAL_PASCAL(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var item models.MODEL_NAME
		if err := c.ShouldBindJSON(&item); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := db.Create(&item).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create item"})
			return
		}
		c.JSON(http.StatusCreated, item)
	}
}

// Update_PLURAL_PASCAL updates an existing item
func Update_PLURAL_PASCAL(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var item models.MODEL_NAME
		if err := db.First(&item, id).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
			return
		}

		if err := c.ShouldBindJSON(&item); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := db.Save(&item).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update item"})
			return
		}
		c.JSON(http.StatusOK, item)
	}
}

// Delete_PLURAL_PASCAL deletes an item
func Delete_PLURAL_PASCAL(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if err := db.Delete(&models.MODEL_NAME{}, id).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete item"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Item deleted successfully"})
	}
}
CONTROLLER_EOF

# Replace placeholders
sed -i "s/MODEL_NAME/${PASCAL_CASE}/g" "controllers/${SNAKE_CASE}.go"
sed -i "s/PLURAL_PASCAL/${PASCAL_CASE}/g" "controllers/${SNAKE_CASE}.go"

echo -e "${GREEN}✓ Created: controllers/${SNAKE_CASE}.go${NC}"

# Generate Routes snippet
echo -e "${BLUE}→ Generating routes snippet...${NC}"

ROUTES_SNIPPET="scripts/${SNAKE_CASE}_routes.txt"
ROUTES_CONTENT="// Add these routes to SetupRoutes() in routes/routes.go\n"
ROUTES_CONTENT+="\n// ${PASCAL_CASE} endpoints\n"

if [ "$HAS_READ" = true ]; then
    ROUTES_CONTENT+="protectedRoutes.GET(\"/${PLURAL_SNAKE}\", controllers.GetAll_${PASCAL_CASE}(db))\n"
    ROUTES_CONTENT+="protectedRoutes.GET(\"/${PLURAL_SNAKE}/:id\", controllers.GetByID_${PASCAL_CASE}(db))\n"
fi

if [ "$HAS_CREATE" = true ]; then
    ROUTES_CONTENT+="protectedRoutes.POST(\"/${PLURAL_SNAKE}\", controllers.Create_${PASCAL_CASE}(db))\n"
fi

if [ "$HAS_UPDATE" = true ]; then
    ROUTES_CONTENT+="protectedRoutes.PUT(\"/${PLURAL_SNAKE}/:id\", controllers.Update_${PASCAL_CASE}(db))\n"
fi

if [ "$HAS_DELETE" = true ]; then
    ROUTES_CONTENT+="protectedRoutes.DELETE(\"/${PLURAL_SNAKE}/:id\", controllers.Delete_${PASCAL_CASE}(db))\n"
fi

echo -e "$ROUTES_CONTENT" > "$ROUTES_SNIPPET"

echo -e "${GREEN}✓ Created: ${ROUTES_SNIPPET}${NC}"

# Generate migration
echo -e "${BLUE}→ Generating migration template...${NC}"
TIMESTAMP=$(date +%s)
MIGRATION_FILE="database/migrations/${TIMESTAMP}_create_${SNAKE_CASE}_table.sql"

cat > "$MIGRATION_FILE" << 'MIGRATION_EOF'
-- Migration: Create PLURAL_SNAKE table
-- Generated automatically

CREATE TABLE IF NOT EXISTS PLURAL_SNAKE (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_PLURAL_SNAKE_deleted_at ON PLURAL_SNAKE(deleted_at);
MIGRATION_EOF

# Replace placeholders
sed -i "s/PLURAL_SNAKE/${PLURAL_SNAKE}/g" "$MIGRATION_FILE"

echo -e "${GREEN}✓ Created: ${MIGRATION_FILE}${NC}"

# Add to registry if not already present
if ! grep -q "^${SNAKE_CASE}$" "$REGISTRY_FILE"; then
    echo "${SNAKE_CASE}" >> "$REGISTRY_FILE"
fi

# Summary
echo ""
echo -e "${GREEN}✅ Endpoint generation complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update the model fields in: ${BLUE}models/${SNAKE_CASE}.go${NC}"
echo "2. Add routes from: ${BLUE}${ROUTES_SNIPPET}${NC}"
echo "3. Review migration: ${BLUE}${MIGRATION_FILE}${NC}"
echo ""
echo -e "${YELLOW}Generated operations:${NC}"
[ "$HAS_READ" = true ] && echo -e "  ${GREEN}✓${NC} Read   (GET /${PLURAL_SNAKE}, GET /${PLURAL_SNAKE}/:id)"
[ "$HAS_CREATE" = true ] && echo -e "  ${GREEN}✓${NC} Create (POST /${PLURAL_SNAKE})"
[ "$HAS_UPDATE" = true ] && echo -e "  ${GREEN}✓${NC} Update (PUT /${PLURAL_SNAKE}/:id)"
[ "$HAS_DELETE" = true ] && echo -e "  ${GREEN}✓${NC} Delete (DELETE /${PLURAL_SNAKE}/:id)"
echo ""
