#!/bin/bash

# colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 [Phase 0] Starting Infrastructure Provisioning...${NC}"

# 1. Create master node
echo -e "${GREEN}[1/3] Creating Master Node (k8s-master)...${NC}"
multipass launch --name k8s-master --cpus 2 --memory 2G --disk 10G

# 2. Create worker node 1
echo -e "${GREEN}[2/3] Creating Worker Node 1 (k8s-worker1)...${NC}"
multipass launch --name k8s-worker1 --cpus 2 --memory 2G --disk 10G

# 3. Create worker node 2
echo -e "${GREEN}[3/3] Creating Worker Node 2 (k8s-worker2)...${NC}"
multipass launch --name k8s-worker2 --cpus 2 --memory 2G --disk 10G

echo -e "${GREEN}✅ Infrastructure Setup Complete!${NC}"
echo -e "${GREEN}Here are your nodes:${NC}"
multipass list