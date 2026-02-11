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
LOG_DIR="$HOME/Docker/logs"
LOG_FILE="$LOG_DIR/docker_update_$(date +%Y-%m-%d).log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages to both console and file
log_plain() {
    local message="$1"
    echo -e "$message"
    # Remove color codes for log file
    echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# Start logging
log_plain "========================================"
log_plain "Docker Update Script"
log_plain "Started: $(date '+%Y-%m-%d %H:%M:%S')"
log_plain "========================================"
log_plain ""

# Check if Docker directory exists
if [ ! -d "$DOCKER_DIR" ]; then
    log_plain "${RED}Error: Docker directory not found at $DOCKER_DIR${NC}"
    exit 1
fi

log_plain "${BLUE}Docker Container Update Script${NC}"
log_plain ""

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
    
    # Skip if not a directory or if it's the logs directory
    [ ! -d "$dir_name" ] && continue
    [[ "$dir_name" == "logs" ]] && continue
    
    total_folders=$((total_folders + 1))
    
    log_plain "${YELLOW}Processing: $dir_name${NC}"
    
    # Check if docker-compose.yml exists
    if [ ! -f "$dir_name/docker-compose.yml" ] && [ ! -f "$dir_name/docker-compose.yaml" ]; then
        log_plain "${RED}  ⚠ No docker-compose.yml found, skipping...${NC}"
        log_plain ""
        continue
    fi
    
    # Navigate to the subdirectory
    cd "$dir_name" || {
        log_plain "${RED}  ✗ Failed to enter directory${NC}"
        failed_updates=$((failed_updates + 1))
        log_plain ""
        continue
    }
    
    # Special handling for immich folder - download latest docker-compose.yml
    if [[ "$dir_name" == "immich" ]]; then
        log_plain "  ${BLUE}Detected Immich folder - downloading latest docker-compose.yml...${NC}"
        
        # Backup existing docker-compose.yml
        if [ -f "docker-compose.yml" ]; then
            cp docker-compose.yml "docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
            log_plain "  ${GREEN}✓ Backed up existing docker-compose.yml${NC}"
        fi
        
        # Download latest docker-compose.yml from Immich GitHub
        if curl -fsSL https://raw.githubusercontent.com/immich-app/immich/main/docker/docker-compose.yml -o docker-compose.yml 2>> "$LOG_FILE"; then
            log_plain "  ${GREEN}✓ Downloaded latest Immich docker-compose.yml${NC}"
        else
            log_plain "  ${RED}✗ Failed to download latest docker-compose.yml${NC}"
            # Restore backup if download failed
            if [ -f "docker-compose.yml.backup."* ]; then
                latest_backup=$(ls -t docker-compose.yml.backup.* | head -1)
                cp "$latest_backup" docker-compose.yml
                log_plain "  ${YELLOW}⚠ Restored from backup${NC}"
            fi
        fi
    fi
    
    # Pull latest images
    log_plain "  ${BLUE}Pulling latest images...${NC}"
    if docker compose pull >> "$LOG_FILE" 2>&1; then
        log_plain "  ${GREEN}✓ Images pulled successfully${NC}"
        
        # Stop and remove containers
        log_plain "  ${BLUE}Stopping containers...${NC}"
        docker compose down >> "$LOG_FILE" 2>&1
        
        # Start containers with new images
        log_plain "  ${BLUE}Starting updated containers...${NC}"
        if docker compose up -d >> "$LOG_FILE" 2>&1; then
            log_plain "  ${GREEN}✓ Containers updated and started successfully${NC}"
            successful_updates=$((successful_updates + 1))
        else
            log_plain "  ${RED}✗ Failed to start containers${NC}"
            failed_updates=$((failed_updates + 1))
        fi
    else
        log_plain "  ${RED}✗ Failed to pull images${NC}"
        failed_updates=$((failed_updates + 1))
    fi
    
    # Return to Docker directory
    cd "$DOCKER_DIR" || exit 1
    log_plain ""
done

# Print summary
log_plain "${BLUE}======================================${NC}"
log_plain "${BLUE}Update Summary${NC}"
log_plain "${BLUE}======================================${NC}"
log_plain "Total folders processed: $total_folders"
log_plain "${GREEN}Successful updates: $successful_updates${NC}"
if [ $failed_updates -gt 0 ]; then
    log_plain "${RED}Failed updates: $failed_updates${NC}"
fi
log_plain ""

log_plain "${GREEN}All done!${NC}"
log_plain "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
log_plain "========================================"
log_plain ""

# Keep only last 30 days of logs
find "$LOG_DIR" -name "docker_update_*.log" -type f -mtime +30 -delete 2>/dev/null
