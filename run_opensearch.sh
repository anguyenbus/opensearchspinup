#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^$1$"
}

# Function to check if container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^$1$"
}

# Function to wait for service to be ready with timeout
wait_for_service() {
    local url=$1
    local service_name=$2
    local timeout=${3:-120}
    local count=0
    
    print_status "Waiting for $service_name to be ready..."
    while [ $count -lt $timeout ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        sleep 2
        count=$((count + 2))
        echo -n "."
    done
    echo ""
    print_error "$service_name failed to start within $timeout seconds"
    return 1
}

# Function to check OpenSearch health
check_opensearch_health() {
    local response=$(curl -s http://localhost:9200/_cluster/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        case $status in
            "green")
                print_success "OpenSearch cluster health: GREEN"
                ;;
            "yellow")
                print_warning "OpenSearch cluster health: YELLOW"
                ;;
            "red")
                print_error "OpenSearch cluster health: RED"
                ;;
            *)
                print_warning "OpenSearch cluster health: UNKNOWN"
                ;;
        esac
        echo "OpenSearch cluster info:"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    else
        print_error "Failed to get OpenSearch health status"
        return 1
    fi
}

print_status "Starting OpenSearch setup using docker-compose..."

# Start services using docker-compose
print_status "Starting containers..."
docker compose -f docker-compose.opensearch.yml up -d

if [ $? -eq 0 ]; then
    print_success "Containers started successfully"
else
    print_error "Failed to start containers with docker compose"
    exit 1
fi

# Wait for OpenSearch to be ready
if ! wait_for_service "http://localhost:9200" "OpenSearch" 120; then
    print_error "OpenSearch failed to start properly"
    exit 1
fi

# Check OpenSearch health
check_opensearch_health

# Wait for OpenSearch Dashboards to be ready
if ! wait_for_service "http://localhost:5601" "OpenSearch Dashboards" 120; then
    print_error "OpenSearch Dashboards failed to start properly"
    exit 1
fi

# Final status check
print_status "Performing final health checks..."

# Check if OpenSearch is responding
if curl -s http://localhost:9200 >/dev/null; then
    print_success "✓ OpenSearch is responding on http://localhost:9200"
else
    print_error "✗ OpenSearch is not responding"
fi

# Check if Dashboards is responding
if curl -s http://localhost:5601 | grep -q "OpenSearch Dashboards"; then
    print_success "✓ OpenSearch Dashboards is responding on http://localhost:5601"
else
    print_error "✗ OpenSearch Dashboards is not responding properly"
fi

# Check network connectivity
print_status "Checking network connectivity..."
if docker exec opensearch-node ping -c 1 opensearch-dashboards >/dev/null 2>&1; then
    print_success "✓ Network connectivity between containers is working"
else
    print_warning "⚠ Network connectivity test failed"
fi

print_success "OpenSearch setup complete!"
print_status "Access OpenSearch at: http://localhost:9200"
print_status "Access OpenSearch Dashboards at: http://localhost:5601"

# Show container status
print_status "Container status:"
docker compose -f docker-compose.opensearch.yml ps