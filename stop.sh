#!/bin/bash
# ==============================================================================
# TITLE:        Automated Multi-Target Penetration Testing Lab Teardown
# DESCRIPTION:  Gracefully stops and removes the multi-container lab environment
#               (AIGoat, Juice Shop, DVWA, WebGoat, bWAPP, and Kasm Kali Linux).
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

clear
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}       🛑 UNIVERSAL PENETRATION TESTING LAB TEARDOWN 🛑         ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Define workspace base path matching the setup script
BASE_WORKSPACE="$(pwd)/universal_pentest_lab"

# Validate Docker state
if ! docker info &> /dev/null; then
    echo -e "${RED}[-][ERROR] Docker daemon does not appear to be running.${NC}"
    echo -e "${YELLOW}[!] Please start Docker and run this script again to clean up containers.${NC}"
    exit 1
fi

# --- Phase 1: Teardown Classic Vulnerabilities Stack ---
echo -e "\n${YELLOW}[*] Phase 1: Halting Classic Web Apps & Kasm Attacker...${NC}"
CLASSIC_PATH="$BASE_WORKSPACE/classic_stack"

if [ -d "$CLASSIC_PATH" ]; then
    cd "$CLASSIC_PATH" || exit
    if [ -f "docker-compose.yml" ]; then
        docker compose down
        echo -e "${GREEN}[+] Classic stack halted and containers removed.${NC}"
    else
        echo -e "${RED}[-][WARNING] docker-compose.yml missing in classic_stack directory.${NC}"
    fi
else
    echo -e "${YELLOW}[!] Classic stack directory not found. Skipping...${NC}"
fi

# --- Phase 2: Teardown AI Vulnerability Layer ---
echo -e "\n${YELLOW}[*] Phase 2: Halting AI Vulnerability Layer (AIGoat)...${NC}"
AIGOAT_PATH="$BASE_WORKSPACE/AIGoat/docker"

if [ -d "$AIGOAT_PATH" ]; then
    cd "$AIGOAT_PATH" || exit
    if [ -f "docker-compose.yml" ]; then
        docker compose down
        echo -e "${GREEN}[+] AIGoat stack halted and containers removed.${NC}"
    else
        echo -e "${RED}[-][WARNING] docker-compose.yml missing in AIGoat/docker directory.${NC}"
    fi
else
    echo -e "${YELLOW}[!] AIGoat deployment directory not found. Skipping...${NC}"
fi

# --- Summary & Data Retention Notice ---
echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}          🎉 LAB ENVIRONMENT SUCCESSFULLY STOPPED 🎉             ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "${YELLOW}NOTE: The 'ollama_models' Docker volume containing the heavy LLM${NC}"
echo -e "${YELLOW}weights has been preserved so you won't have to re-download them${NC}"
echo -e "${YELLOW}the next time you spin up the lab.${NC}"
echo -e "${BLUE}================================================================${NC}"
