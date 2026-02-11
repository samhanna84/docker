#!/bin/bash

# Script to update all Docker containers in ~/Docker subdirectories
# Each subdirectory should contain a docker-compose.yml file

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOCKER_DIR="$HOME/Docker"

# Check if Docker directory exists
if [ ! -d "$DOCKER_DIR" ]; then
    echo -e "${RED}Error: Docker directory not found at $DOCKER_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Docker Container Update Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Navigate to Docker directory
cd "$DOCKER_DIR" || exit 1

# Counter for statistics
total_folders=0
successful_updates=0
failed_updates=0

# Loop through each subdirectory
for dir in */; do
    # Remove trailing slash
    dir_name="${dir%/}"
    
    # Skip if not a directory
    [ ! -d "$dir_name" ] && continue
    
    total_folders=$((total_folders + 1))
    
    echo -e "${YELLOW}Processing: $dir_name${NC}"
    
    # Check if docker-compose.yml exists
    if [ ! -f "$dir_name/docker-compose.yml" ] && [ ! -f "$dir_name/docker-compose.yaml" ]; then
        echo -e "${RED}  ⚠ No docker-compose.yml found, skipping...${NC}"
        echo ""
        continue
    fi
    
    # Navigate to the subdirectory
    cd "$dir_name" || {
        echo -e "${RED}  ✗ Failed to enter directory${NC}"
        failed_updates=$((failed_updates + 1))
        echo ""
        continue
    }
    
    # Special handling for immich folder - download latest docker-compose.yml
    if [[ "$dir_name" == "immich" ]]; then
        echo -e "  ${BLUE}Detected Immich folder - downloading latest docker-compose.yml...${NC}"
        
        # Backup existing docker-compose.yml
        if [ -f "docker-compose.yml" ]; then
            cp docker-compose.yml "docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "  ${GREEN}✓ Backed up existing docker-compose.yml${NC}"
        fi
        
        # Download latest docker-compose.yml from Immich GitHub
        if curl -fsSL https://raw.githubusercontent.com/immich-app/immich/main/docker/docker-compose.yml -o docker-compose.yml; then
            echo -e "  ${GREEN}✓ Downloaded latest Immich docker-compose.yml${NC}"
        else
            echo -e "  ${RED}✗ Failed to download latest docker-compose.yml${NC}"
            # Restore backup if download failed
            if [ -f "docker-compose.yml.backup."* ]; then
                latest_backup=$(ls -t docker-compose.yml.backup.* | head -1)
                cp "$latest_backup" docker-compose.yml
                echo -e "  ${YELLOW}⚠ Restored from backup${NC}"
            fi
        fi
    fi
    
    # Pull latest images
    echo -e "  ${BLUE}Pulling latest images...${NC}"
    if docker compose pull; then
        echo -e "  ${GREEN}✓ Images pulled successfully${NC}"
        
        # Stop and remove containers
        echo -e "  ${BLUE}Stopping containers...${NC}"
        docker compose down
        
        # Start containers with new images
        echo -e "  ${BLUE}Starting updated containers...${NC}"
        if docker compose up -d; then
            echo -e "  ${GREEN}✓ Containers updated and started successfully${NC}"
            successful_updates=$((successful_updates + 1))
        else
            echo -e "  ${RED}✗ Failed to start containers${NC}"
            failed_updates=$((failed_updates + 1))
        fi
    else
        echo -e "  ${RED}✗ Failed to pull images${NC}"
        failed_updates=$((failed_updates + 1))
    fi
    
    # Return to Docker directory
    cd "$DOCKER_DIR" || exit 1
    echo ""
done

# Print summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Update Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Total folders processed: $total_folders"
echo -e "${GREEN}Successful updates: $successful_updates${NC}"
if [ $failed_updates -gt 0 ]; then
    echo -e "${RED}Failed updates: $failed_updates${NC}"
fi
echo ""

echo -e "${GREEN}All done!${NC}"
