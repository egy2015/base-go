#!/bin/bash


# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arguments
RESOURCE_NAME="$1"

if [ -z "$RESOURCE_NAME" ]; then
    echo -e "${RED}Error: Resource name is required${NC}"
    echo "Usage: $0 <resource_name>"
    exit 1
fi

# Convert to snake_case
SNAKE_CASE=$(echo "$RESOURCE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_$//')

# Path to the registry file
REGISTRY_FILE="scripts/.generated_endpoints"

# Check if resource exists in registry
if [ ! -f "$REGISTRY_FILE" ] || ! grep -q "^${SNAKE_CASE}$" "$REGISTRY_FILE"; then
    echo -e "${RED}Error: Endpoint '${SNAKE_CASE}' not found in registry${NC}"
    echo -e "${YELLOW}Generated endpoints:${NC}"
    if [ -f "$REGISTRY_FILE" ]; then
        cat "$REGISTRY_FILE" | sed 's/^/  - /'
    else
        echo "  No endpoints generated yet"
    fi
    exit 1
fi

echo -e "${BLUE}Rolling back endpoint: ${SNAKE_CASE}${NC}"
echo ""

# Step 1: Delete model file
MODEL_FILE="models/${SNAKE_CASE}.go"
if [ -f "$MODEL_FILE" ]; then
    rm "$MODEL_FILE"
    echo -e "${GREEN}✓ Deleted: $MODEL_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Model file not found: $MODEL_FILE${NC}"
fi

# Step 2: Delete controller file
CONTROLLER_FILE="controllers/${SNAKE_CASE}.go"
if [ -f "$CONTROLLER_FILE" ]; then
    rm "$CONTROLLER_FILE"
    echo -e "${GREEN}✓ Deleted: $CONTROLLER_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Controller file not found: $CONTROLLER_FILE${NC}"
fi

# Step 3: Delete routes snippet
ROUTES_FILE="scripts/${SNAKE_CASE}_routes.txt"
if [ -f "$ROUTES_FILE" ]; then
    rm "$ROUTES_FILE"
    echo -e "${GREEN}✓ Deleted: $ROUTES_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Routes file not found: $ROUTES_FILE${NC}"
fi

# Step 4: Find and delete migration file
MIGRATION_FILE=$(find database/migrations -name "*_${SNAKE_CASE}_table.sql" 2>/dev/null | head -1)
if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    rm "$MIGRATION_FILE"
    echo -e "${GREEN}✓ Deleted: $MIGRATION_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Migration file not found (manual cleanup may be needed)${NC}"
fi

# Step 5: Remove from registry first
if [ -f "$REGISTRY_FILE" ]; then
    sed -i "/^${SNAKE_CASE}$/d" "$REGISTRY_FILE"
    echo -e "${GREEN}✓ Removed from registry${NC}"
fi

echo -e "${BLUE}→ Cleaning up orphaned registry entries...${NC}"
ORPHANED_COUNT=0

if [ -f "$REGISTRY_FILE" ]; then
    # Create a temporary file for cleaned registry
    TEMP_REGISTRY="${REGISTRY_FILE}.tmp"
    > "$TEMP_REGISTRY"
    
    while IFS= read -r endpoint; do
        # Skip empty lines
        [ -z "$endpoint" ] && continue
        
        # Check if both model and controller exist
        if [ -f "models/${endpoint}.go" ] && [ -f "controllers/${endpoint}.go" ]; then
            echo "$endpoint" >> "$TEMP_REGISTRY"
        else
            echo -e "${YELLOW}⚠ Removing orphaned entry: ${endpoint}${NC}"
            ((ORPHANED_COUNT++))
        fi
    done < "$REGISTRY_FILE"
    
    # Replace original with cleaned version
    mv "$TEMP_REGISTRY" "$REGISTRY_FILE"
    
    if [ $ORPHANED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓ Cleaned ${ORPHANED_COUNT} orphaned entries${NC}"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}✅ Rollback complete!${NC}"
echo ""
echo -e "${YELLOW}Manual cleanup required:${NC}"
echo "1. Remove route registrations from: ${BLUE}routes/routes.go${NC}"
echo "   (Look for routes matching: /${SNAKE_CASE})"
echo ""

if [ -f "$REGISTRY_FILE" ] && [ -s "$REGISTRY_FILE" ]; then
    echo -e "${YELLOW}Remaining generated endpoints:${NC}"
    cat "$REGISTRY_FILE" | sed 's/^/  - /'
else
    echo -e "${YELLOW}No endpoints remaining${NC}"
fi
echo ""
