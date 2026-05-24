#!/bin/bash
# ==============================================================================
# TITLE:        Automated Multi-Target Penetration Testing Lab Setup
# DESCRIPTION:  Deploys a multi-container environment including patched AIGoat,
#               Juice Shop, DVWA, WebGoat, bWAPP, and Kasm Kali Linux.
#               FEATURES: Interactive Network Binding & GPU Support.
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

clear
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}        🚀 UNIVERSAL PENETRATION TESTING LAB DEPLOYER 🚀         ${NC}"
echo -e "${BLUE}================================================================${NC}"

# --- Phase 1: Prerequisite Validation ---
echo -e "\n${YELLOW}[*] Phase 1: Validating System Dependencies...${NC}"

deps=("git" "docker" "curl")
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        echo -e "${RED}[-][ERROR] Missing required dependency: $dep${NC}"
        echo -e "${YELLOW}[!] Please install $dep via your package manager and try again.${NC}"
        exit 1
    fi
done

if ! docker compose version &> /dev/null; then
    echo -e "${RED}[-][ERROR] Docker Compose V2 (docker compose) is required but not found.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] All core system prerequisites satisfied.${NC}"

# --- Phase 2: Interactive Network Configuration ---
echo -e "\n${YELLOW}[*] Phase 2: Network Interface Configuration...${NC}"
echo -e "Available local interfaces detected on this machine:"
hostname -I | tr ' ' '\n' | grep -v '^$' | awk '{print "  [•] " $1}'

echo -e "\n${RED}[!] VIRTUALIZATION / WSL WARNING:${NC}"
echo -e "${YELLOW}Do NOT select internal NAT addresses (like 172.x.x.x). You must input${NC}"
echo -e "${YELLOW}the real physical IP of the host machine (e.g., 192.168.100.6).${NC}\n"

echo -an "${BLUE}👉 Enter the exact IP address you will use to browse this lab: ${NC}"
read -r TARGET_IP

if [ -z "$TARGET_IP" ]; then
    echo -e "${RED}[-][ERROR] Target IP selection cannot be blank. Execution aborted.${NC}"
    exit 1
fi

# --- Phase 3: Directory Scaffolding ---
echo -e "\n${YELLOW}[*] Phase 3: Allocating Workspace Environment...${NC}"
# Modified to establish the workspace inside the current working directory
BASE_WORKSPACE="$(pwd)/universal_pentest_lab"
mkdir -p "$BASE_WORKSPACE"
cd "$BASE_WORKSPACE" || exit
echo -e "${GREEN}[+] Workspace established at: $BASE_WORKSPACE${NC}"

# --- Phase 4: AIGoat Cloner & Source Patch Engine ---
echo -e "\n${YELLOW}[*] Phase 4: Constructing AI Vulnerability Layer (AIGoat)...${NC}"
if [ -d "AIGoat" ]; then
    echo -e "${YELLOW}[!] Existing AIGoat repository found. Resetting state...${NC}"
    cd AIGoat && git reset --hard HEAD && git clean -fd && git pull && cd ..
else
    echo -e "${BLUE}[+] Cloning official AIGoat repository...${NC}"
    git clone https://github.com/AISecurityConsortium/AIGoat.git
fi

cd AIGoat || exit

echo -e "${BLUE}[+] Forcing compiled source configuration to bind to $TARGET_IP...${NC}"
find . -type f -not -path '*/.*' -exec sed -i "s/localhost:8000/${TARGET_IP}:8000/g" {} + 2>/dev/null
find . -type f -not -path '*/.*' -exec sed -i "s/127.0.0.1:8000/${TARGET_IP}:8000/g" {} + 2>/dev/null
find . -type f -not -path '*/.*' -exec sed -i "s/localhost:3000/${TARGET_IP}:3000/g" {} + 2>/dev/null
find . -type f -not -path '*/.*' -exec sed -i "s/127.0.0.1:3000/${TARGET_IP}:3000/g" {} + 2>/dev/null

echo -e "${BLUE}[+] Patching Python backend CORS policies globally...${NC}"
find . -type f -name "*.py" -exec sed -i 's/allow_origins=\[.*\]/allow_origins=\["*"\]/g' {} + 2>/dev/null

echo -e "${BLUE}[+] Re-allocating Ollama External Host Port Mapping to 11438...${NC}"
cd docker || exit
sed -i 's/11434:11434/11438:11434/g' docker-compose.yml

echo -e "${BLUE}[+] Injecting GPU Acceleration Device Reservations...${NC}"
cat << 'EOF' > docker-compose.override.yml
services:
  ollama:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF

echo -e "${GREEN}[+] Initializing AIGoat Image Compilation Sequence...${NC}"
docker volume create ollama_models &> /dev/null || true
docker compose up --build -d
cd "$BASE_WORKSPACE" || exit

# --- Phase 5: Classic Vulnerabilities & Attacker Integration ---
echo -e "\n${YELLOW}[*] Phase 5: Building Web Vuln Stack & Kasm Attacker...${NC}"
mkdir -p classic_stack
cd classic_stack || exit

cat << 'EOF' > docker-compose.yml
services:
  juice-shop:
    image: bkimminich/juice-shop
    container_name: juice-shop
    ports:
      - "3001:3000"
    restart: unless-stopped

  dvwa:
    image: vulnerables/web-dvwa
    container_name: dvwa
    ports:
      - "8080:80"
    restart: unless-stopped

  webgoat:
    image: webgoat/webgoat
    container_name: webgoat
    ports:
      - "8081:8080"
      - "9090:9090" 
    restart: unless-stopped

  bwapp:
    image: raesene/bwapp
    container_name: bwapp
    ports:
      - "8082:80"
    restart: unless-stopped

  kasm-kali:
    image: kasmweb/kali-rolling-desktop:1.17.0
    container_name: kasm-kali
    user: root
    ports:
      - "6905:6901" 
    environment:
      - VNC_PW=password123 
    shm_size: "512m"
    restart: unless-stopped
EOF

echo -e "${GREEN}[+] Launching Classic Target Apps and Attacker Infrastructure...${NC}"
docker compose up -d

# --- Final Synchronization Display ---
clear
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}         🎉 PRODUCTION PORTABLE LAB DEPLOYMENT SUCCESS 🎉        ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "${YELLOW}Please allow 5-15 minutes for AIGoat's background layer to${NC}"
echo -e "${YELLOW}fully pull down the 4.5GB Mistral LLM model on first initialization.${NC}"
echo -e "\n${BLUE}🌐 LAB TARGET MAP (AVAILABLE TO ANY DEVICE ON NETWORK):${NC}"
echo -e "  • ${GREEN}AIGoat Application:${NC}   http://$TARGET_IP:3000"
echo -e "  • ${GREEN}OWASP Juice Shop:${NC}     http://$TARGET_IP:3001"
echo -e "  • ${GREEN}DVWA Platform:${NC}        http://$TARGET_IP:8080"
echo -e "  • ${GREEN}WebGoat Suite:${NC}        http://$TARGET_IP:8081/WebGoat"
echo -e "  • ${GREEN}bWAPP Installer:${NC}      http://$TARGET_IP:8082/install.php"
echo -e "  • ${GREEN}Ollama API Gateway:${NC}   http://$TARGET_IP:11438  (GPU Accelerated)"
echo -e "\n${BLUE}🖥️  INTEGRATED WEB ATTACK MACHINE:${NC}"
echo -e "  • ${GREEN}Kasm Kali Desktop:${NC}  https://$TARGET_IP:6905"
echo -e "    ${YELLOW}Username:${NC} kasm_user  |  ${YELLOW}Password:${NC} password123"
echo -e "${GREEN}================================================================${NC}"
