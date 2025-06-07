# OpenSearch Docker Setup

This setup provides a robust and well-monitored OpenSearch environment with comprehensive health checks and management capabilities.

## Quick Start

```bash
# Start OpenSearch and Dashboards
./run_opensearch.sh

# Check health status
./manage_opensearch.sh health

# Check container status
./manage_opensearch.sh status
```

## What's Included

### Core Services
- **OpenSearch Node**: Search and analytics engine (port 9200)
- **OpenSearch Dashboards**: Web interface for data visualization (port 5601)
- **Custom Network**: Isolated Docker network for secure communication

### Key Improvements Made

1. **Enhanced Error Handling**: Script now handles existing containers gracefully
2. **Security Configuration**: SSL disabled for easier local development
3. **Health Monitoring**: Comprehensive health checks with detailed status reporting
4. **Resource Optimization**: Proper memory limits and Java heap settings
5. **Network Reliability**: Better network connectivity testing and reporting
6. **Colored Output**: Easy-to-read status messages with color coding

## Scripts

### `run_opensearch.sh` - Main Setup Script

**Features:**
- ✅ Handles existing containers without conflicts
- ✅ Creates network if it doesn't exist
- ✅ Waits for services to be fully ready
- ✅ Performs health checks after startup
- ✅ Shows final status and access URLs
- ✅ Memory-optimized configuration
- ✅ Security plugins disabled for local development

**Usage:**
```bash
./run_opensearch.sh
```

### `manage_opensearch.sh` - Management Tool

**Commands:**

| Command | Description |
|---------|-------------|
| `start` | Start OpenSearch containers |
| `stop` | Stop OpenSearch containers |
| `restart` | Restart OpenSearch containers |
| `status` | Show container status |
| `health` | Comprehensive health check |
| `logs` | View container logs |
| `clean` | Remove containers and network |

**Examples:**
```bash
# Check overall health
./manage_opensearch.sh health

# View logs
./manage_opensearch.sh logs

# Restart everything
./manage_opensearch.sh restart

# Clean up everything
./manage_opensearch.sh clean
```

## Health Check Details

The health check verifies:

1. **OpenSearch API Accessibility**: Tests if the search engine responds
2. **Cluster Health**: Reports cluster status (Green/Yellow/Red)
3. **Dashboards Accessibility**: Verifies web interface is working
4. **Network Connectivity**: Tests inter-container communication
5. **Resource Usage**: Shows CPU and memory consumption

## Access URLs

- **OpenSearch API**: http://localhost:9200
- **OpenSearch Dashboards**: http://localhost:5601

## Configuration Details

### OpenSearch Node
- **Image**: `opensearchproject/opensearch:2.11.0`
- **Memory**: 512MB heap size (optimized for local development)
- **Security**: Disabled for easier development
- **Ports**: 9200 (HTTP), 9600 (Performance Analyzer)

### OpenSearch Dashboards
- **Image**: `opensearchproject/opensearch-dashboards:2.11.0`
- **Security**: Disabled to match OpenSearch configuration
- **Port**: 5601 (Web Interface)

## Status Indicators

The scripts use color-coded status indicators:

- 🔵 **[INFO]** - General information
- 🟢 **[SUCCESS]** - Operation completed successfully
- 🟡 **[WARNING]** - Warning or non-critical issue
- 🔴 **[ERROR]** - Critical error requiring attention

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using the ports
   lsof -i :9200
   lsof -i :5601
   ```

2. **Containers Won't Start**
   ```bash
   # Check logs for errors
   ./manage_opensearch.sh logs
   ```

3. **Network Issues**
   ```bash
   # Clean up and restart
   ./manage_opensearch.sh clean
   ./run_opensearch.sh
   ```

4. **Performance Issues**
   ```bash
   # Check resource usage
   ./manage_opensearch.sh health
   ```

## Network Architecture

```
┌─────────────────────────┐
│     opensearch-net      │
│     (Docker Network)    │
│                         │
│  ┌─────────────────┐   │
│  │ opensearch-node │   │
│  │   Port: 9200    │   │
│  └─────────────────┘   │
│           │             │
│           │             │
│  ┌─────────────────┐   │
│  │opensearch-dash- │   │
│  │boards           │   │
│  │   Port: 5601    │   │
│  └─────────────────┘   │
└─────────────────────────┘
```

## Security Note

This configuration has security plugins disabled for local development. For production use, enable security features and configure proper authentication. 