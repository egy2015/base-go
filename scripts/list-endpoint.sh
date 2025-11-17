#!/bin/bash


# Color codes for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REGISTRY_FILE="scripts/.generated_endpoints"

echo -e "${BLUE}Generated Endpoints${NC}"
echo -e "${BLUE}===================${NC}"
echo ""

if [ ! -f "$REGISTRY_FILE" ] || [ ! -s "$REGISTRY_FILE" ]; then
    echo -e "${YELLOW}No endpoints generated yet${NC}"
    exit 0
fi

echo -e "${GREEN}Available endpoints:${NC}"
ORPHANED_COUNT=0
while IFS= read -r endpoint; do
    if [ -z "$endpoint" ]; then
        continue
    fi
    
    if [ -f "models/${endpoint}.go" ] && [ -f "controllers/${endpoint}.go" ]; then
        echo -e "  ${GREEN}✓${NC} ${endpoint}"
    else
        echo -e "  ${RED}✗${NC} ${endpoint} (orphaned - run: make clean-registry)"
        ((ORPHANED_COUNT++))
    fi
done < "$REGISTRY_FILE"

echo ""
echo -e "${YELLOW}View endpoint details:${NC}"
echo "  cat models/[endpoint].go"
echo "  cat controllers/[endpoint].go"
echo "  cat scripts/[endpoint]_routes.txt"
echo ""
echo -e "${YELLOW}Manage endpoints:${NC}"
echo "  make create-endpoint NAME=[endpoint] METHODS=[methods]"
echo "  make rollback NAME=[endpoint]"
echo ""

if [ $ORPHANED_COUNT -gt 0 ]; then
    echo -e "${RED}⚠ Found ${ORPHANED_COUNT} orphaned endpoints${NC}"
    echo "Run: make clean-registry"
    echo ""
fi
