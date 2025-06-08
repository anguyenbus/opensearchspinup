#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to show usage
show_usage() {
    echo "Usage: $0 {start|stop|restart|status|health|logs|clean}"
    echo ""
    echo "Commands:"
    echo "  start   - Start OpenSearch containers"
    echo "  stop    - Stop OpenSearch containers"
    echo "  restart - Restart OpenSearch containers"
    echo "  status  - Show container status"
    echo "  health  - Perform comprehensive health check"
    echo "  logs    - Show container logs"
    echo "  clean   - Stop and remove containers and network"
}

# Function to check container status
check_status() {
    print_status "OpenSearch Container Status:"
    docker ps --filter "name=opensearch" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Check if containers are running
    if docker ps | grep -q opensearch-node; then
        print_success "✓ OpenSearch node is running"
    else
        print_error "✗ OpenSearch node is not running"
    fi
    
    if docker ps | grep -q opensearch-dashboards; then
        print_success "✓ OpenSearch Dashboards is running"
    else
        print_error "✗ OpenSearch Dashboards is not running"
    fi
}

# Function to perform health check
health_check() {
    print_status "Performing comprehensive health check..."
    echo ""
    
    # Check OpenSearch API
    print_status "Checking OpenSearch API..."
    if curl -s http://localhost:9200 >/dev/null 2>&1; then
        print_success "✓ OpenSearch API is accessible"
        
        # Get cluster health
        local health_response=$(curl -s http://localhost:9200/_cluster/health 2>/dev/null)
        if [ $? -eq 0 ]; then
            local status=$(echo "$health_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            local nodes=$(echo "$health_response" | grep -o '"number_of_nodes":[0-9]*' | cut -d':' -f2)
            local indices=$(echo "$health_response" | grep -o '"active_primary_shards":[0-9]*' | cut -d':' -f2)
            
            echo "  Cluster Status: $status"
            echo "  Number of Nodes: $nodes"
            echo "  Active Shards: $indices"
        fi
    else
        print_error "✗ OpenSearch API is not accessible"
    fi
    
    echo ""
    
    # Check Dashboards
    print_status "Checking OpenSearch Dashboards..."
    if curl -s http://localhost:5601 >/dev/null 2>&1; then
        print_success "✓ OpenSearch Dashboards is accessible"
    else
        print_error "✗ OpenSearch Dashboards is not accessible"
    fi
    
    echo ""
    
    # Check network
    print_status "Checking network connectivity..."
    if docker network ls | grep -q opensearch-net; then
        print_success "✓ opensearch-net network exists"
        
        # Test inter-container connectivity
        if docker exec opensearch-node ping -c 1 opensearch-dashboards >/dev/null 2>&1; then
            print_success "✓ Network connectivity between containers is working"
        else
            print_warning "⚠ Network connectivity test failed"
        fi
    else
        print_error "✗ opensearch-net network does not exist"
    fi
    
    echo ""
    
    # Check resource usage
    print_status "Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" opensearch-node opensearch-dashboards 2>/dev/null
}

# Function to show logs
show_logs() {
    echo "Which logs would you like to see?"
    echo "1) OpenSearch Node"
    echo "2) OpenSearch Dashboards"
    echo "3) Both"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            print_status "OpenSearch Node logs (last 50 lines):"
            docker compose -f docker-compose.opensearch.yml logs --tail 50 opensearch-node
            ;;
        2)
            print_status "OpenSearch Dashboards logs (last 50 lines):"
            docker compose -f docker-compose.opensearch.yml logs --tail 50 opensearch-dashboards
            ;;
        3)
            print_status "OpenSearch Node logs (last 25 lines):"
            docker compose -f docker-compose.opensearch.yml logs --tail 25 opensearch-node
            echo ""
            print_status "OpenSearch Dashboards logs (last 25 lines):"
            docker compose -f docker-compose.opensearch.yml logs --tail 25 opensearch-dashboards
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to start containers
start_containers() {
    print_status "Starting OpenSearch containers..."
    ./run_opensearch.sh
}

# Function to stop containers
stop_containers() {
    print_status "Stopping OpenSearch containers..."
    docker compose -f docker-compose.opensearch.yml stop
    print_success "Containers stopped"
}

# Function to restart containers
restart_containers() {
    print_status "Restarting OpenSearch containers..."
    docker compose -f docker-compose.opensearch.yml restart
}

# Function to clean up everything
clean_up() {
    print_warning "This will stop and remove all OpenSearch containers and the network."
    read -p "Are you sure? (y/N): " confirm
    
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        print_status "Removing containers and network..."
        docker compose -f docker-compose.opensearch.yml down -v
        
        print_success "Cleanup complete"
    else
        print_status "Cleanup cancelled"
    fi
}

# Main script logic
case "$1" in
    start)
        start_containers
        ;;
    stop)
        stop_containers
        ;;
    restart)
        restart_containers
        ;;
    status)
        check_status
        ;;
    health)
        health_check
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_up
        ;;
    *)
        show_usage
        exit 1
        ;;
esac 