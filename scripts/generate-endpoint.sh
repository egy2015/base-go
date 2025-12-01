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
PASCAL_CASE=$(echo "$SNAKE_CASE" | sed 's/\b$$.$$/\u\1/g')
CAMEL_CASE=$(echo "$SNAKE_CASE" | sed 's/\b$$.$$/\u\1/g; s/^.$$.*$$/\l\1/')
PLURAL_SNAKE="${SNAKE_CASE}s"
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
cat > "models/${SNAKE_CASE}.go" << "MODEL_EOF"
package models

import (
	"time"

	"gorm.io/gorm"
)

// ${PASCAL_CASE} represents a ${PASCAL_CASE} record
type ${PASCAL_CASE} struct {
	ID        uint      \`gorm:"primaryKey" json:"id"\`
	Name      string    \`gorm:"not null;index" json:"name"\`
	CreatedAt time.Time \`json:"created_at"\`
	UpdatedAt time.Time \`json:"updated_at"\`
	DeletedAt gorm.DeletedAt \`gorm:"index" json:"deleted_at,omitempty"\`
}

// TableName specifies the table name
func (${PASCAL_CASE}) TableName() string {
	return "${PLURAL_SNAKE}"
}
MODEL_EOF

echo -e "${GREEN}✓ Created: models/${SNAKE_CASE}.go${NC}"

# Generate Controller
echo -e "${BLUE}→ Generating controller...${NC}"

# Build controller functions based on requested methods
CONTROLLER_FUNCTIONS=""

if [ "$HAS_READ" = true ]; then
    CONTROLLER_FUNCTIONS+="
// GetAll_${PASCAL_CASE} retrieves all items
func GetAll_${PASCAL_CASE}(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var items []models.${PASCAL_CASE}
		if err := db.Find(&items).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{\"error\": \"Failed to fetch items\"})
			return
		}
		c.JSON(http.StatusOK, items)
	}
}

// GetByID_${PASCAL_CASE} retrieves a single item by ID
func GetByID_${PASCAL_CASE}(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param(\"id\")
		var item models.${PASCAL_CASE}
		if err := db.First(&item, id).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{\"error\": \"Item not found\"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{\"error\": \"Database error\"})
			return
		}
		c.JSON(http.StatusOK, item)
	}
}
"
fi

if [ "$HAS_CREATE" = true ]; then
    CONTROLLER_FUNCTIONS+="
// Create_${PASCAL_CASE} creates a new item
func Create_${PASCAL_CASE}(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var item models.${PASCAL_CASE}
		if err := c.ShouldBindJSON(&item); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{\"error\": err.Error()})
			return
		}

		if err := db.Create(&item).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{\"error\": \"Failed to create item\"})
			return
		}
		c.JSON(http.StatusCreated, item)
	}
}
"
fi

if [ "$HAS_UPDATE" = true ]; then
    CONTROLLER_FUNCTIONS+="
// Update_${PASCAL_CASE} updates an existing item
func Update_${PASCAL_CASE}(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param(\"id\")
		var item models.${PASCAL_CASE}
		if err := db.First(&item, id).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{\"error\": \"Item not found\"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{\"error\": \"Database error\"})
			return
		}

		if err := c.ShouldBindJSON(&item); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{\"error\": err.Error()})
			return
		}

		if err := db.Save(&item).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{\"error\": \"Failed to update item\"})
			return
		}
		c.JSON(http.StatusOK, item)
	}
}
"
fi

if [ "$HAS_DELETE" = true ]; then
    CONTROLLER_FUNCTIONS+="
// Delete_${PASCAL_CASE} deletes an item
func Delete_${PASCAL_CASE}(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param(\"id\")
		if err := db.Delete(&models.${PASCAL_CASE}{}, id).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{\"error\": \"Failed to delete item\"})
			return
		}
		c.JSON(http.StatusOK, gin.H{\"message\": \"Item deleted successfully\"})
	}
}
"
fi

cat > "controllers/${SNAKE_CASE}.go" << CONTROLLER_EOF
package controllers

import (
	"api/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

${CONTROLLER_FUNCTIONS}
CONTROLLER_EOF

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

cat > "$MIGRATION_FILE" << "MIGRATION_EOF"
-- Migration: Create ${PLURAL_SNAKE} table
-- Generated automatically

CREATE TABLE IF NOT EXISTS ${PLURAL_SNAKE} (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_${PLURAL_SNAKE}_deleted_at ON ${PLURAL_SNAKE}(deleted_at);
MIGRATION_EOF

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
