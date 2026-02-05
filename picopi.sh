#!/bin/bash

################################################################################
#                            PICOPI VAULT v1.0                                 #
#                         Password Manager Script                              #
################################################################################

# ==============================================================================
# CONFIGURATION
# ==============================================================================

VAULT_DIR="$HOME/.myvault"
export GPG_TTY=$(tty) 
FAIL_COUNT=0

# ------------------------------------------------------------------------------
# Color Definitions
# ------------------------------------------------------------------------------

CYAN='\033[0;36m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m' 

# ------------------------------------------------------------------------------
# Emergency Shutdown Trap
# ------------------------------------------------------------------------------

trap 'echo -e "\n${RED}Emergency Shutdown...${NC}"; exit' SIGINT

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# Display splash screen with ASCII art logo
# ------------------------------------------------------------------------------

show_splash() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██╗ ██████╗ ██████╗ ██████╗ ██╗"
    echo "  ██╔══██╗██║██╔════╝██╔═══██╗██╔══██╗██║"
    echo "  ██████╔╝██║██║     ██║   ██║██████╔╝██║"
    echo "  ██╔═══╝ ██║██║     ██║   ██║██╔═══╝ ██║"
    echo "  ██║     ██║╚██████╗╚██████╔╝██║     ██║"
    echo "  ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝"
    echo -e "             PICOPI VAULT v1.0${NC}\n"
    sleep 0.5
}

# ------------------------------------------------------------------------------
# Typewriter effect for text output
# ------------------------------------------------------------------------------

typewriter() {
    local text="$1"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep 0.03
    done
    echo ""
}

# ------------------------------------------------------------------------------
# Check git synchronization status with remote
# ------------------------------------------------------------------------------

check_sync_status() {
    if [ ! -d "$VAULT_DIR/.git" ]; then
        SYNC_STATUS="${YELLOW}● Offline${NC}"
        return
    fi
    
    # Quick check for internet and remote updates
    if git fetch --timeout=2 origin main &>/dev/null; then
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})
        if [ "$LOCAL" = "$REMOTE" ]; then
            SYNC_STATUS="${GREEN}● Synced${NC}"
        else
            SYNC_STATUS="${RED}● Update!${NC}"
        fi
    else
        SYNC_STATUS="${RED}● No Link${NC}"
    fi
}

# ------------------------------------------------------------------------------
# Add a new password to the vault
# ------------------------------------------------------------------------------

add_password() {
    clear
    echo -e "${BLUE}--- PICOPI: ADD NEW CREDENTIAL ---${NC}"
    
    echo -ne "${YELLOW}Service Name:${NC} "
    read service
    
    echo -ne "${YELLOW}Enter Password for $service:${NC} "
    read -s password
    echo ""

    echo -ne "${CYAN}Encrypting... [          ]${NC}\r"
    sleep 0.3
    echo -ne "${CYAN}Encrypting... [#####     ]${NC}\r"
    
    if echo "$password" | gpg --batch --yes --symmetric --cipher-algo AES256 -o "$VAULT_DIR/$service.gpg" 2>/dev/null; then
        echo -ne "${CYAN}Encrypting... [##########]${NC}\n"
        echo -e "${GREEN}SUCCESS: $service has been locked in PICOPI.${NC}"
        
        # Auto-Sync to GitHub
        cd "$VAULT_DIR" && git add . && git commit -m "PICOPI Update: $service" &>/dev/null
        git push origin main &>/dev/null &
    else
        echo -e "${RED}ERROR: GPG failed to encrypt the data.${NC}"
    fi
    
    sleep 2
}

# ------------------------------------------------------------------------------
# Retrieve and copy password to clipboard
# ------------------------------------------------------------------------------

get_password() {
    clear
    echo -e "${BLUE}--- PICOPI: RETRIEVE CREDENTIAL ---${NC}"
    
    echo -ne "${YELLOW}Enter service name:${NC} "
    read service

    if [ -f "$VAULT_DIR/$service.gpg" ]; then
        if gpg --batch --quiet --decrypt "$VAULT_DIR/$service.gpg" > /dev/null 2>&1; then
            FAIL_COUNT=0
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ACCESS: $service" >> "$VAULT_DIR/.vault_log"
            gpg -d -q "$VAULT_DIR/$service.gpg" 2>/dev/null | xclip -selection clipboard
            echo -e "${GREEN}Access Granted. Copied to clipboard!${NC}"
            
            # Countdown timer before clearing clipboard
            for i in {10..1}; do
                bar=$(printf "%${i}s" | tr ' ' '#')
                space=$(printf "%$((10-i))s")
                echo -ne "${RED}Time Left: [${bar}${space}] ${i}s ${NC}\r"
                sleep 1
            done
            
            echo "" | xclip -selection clipboard
            echo -e "\n${BLUE}🧹 Clipboard cleared.${NC}"
            sleep 1
        else
            ((FAIL_COUNT++))
            echo -e "${RED}ACCESS DENIED: Strike $FAIL_COUNT of 3${NC}"
            [ $FAIL_COUNT -ge 3 ] && trigger_lockdown || sleep 2
        fi
    else
        echo -e "${RED}Error: '$service' not found in PICOPI.${NC}"
        sleep 2
    fi
}

# ------------------------------------------------------------------------------
# Generate a random strong password
# ------------------------------------------------------------------------------

gen_password() {
    clear
    echo -e "${BLUE}--- PICOPI: PASSWORD GENERATOR ---${NC}"
    
    new_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)
    echo -e "${YELLOW}Generated:${NC} ${WHITE}$new_pass${NC}"
    echo -e "${CYAN}Tip: Use 'Add Password' to save this in PICOPI.${NC}"
}

# ------------------------------------------------------------------------------
# List all stored passwords in the vault
# ------------------------------------------------------------------------------

list_passwords() {
    clear
    echo -e "${BLUE}--- PICOPI: VAULT CONTENTS ---${NC}"
    echo -e "${CYAN}-------------------------------${NC}"
    
    if [ -z "$(ls -A "$VAULT_DIR"/*.gpg 2>/dev/null)" ]; then
        echo -e "${YELLOW}Vault is empty.${NC}"
    else
        ls "$VAULT_DIR" | grep ".gpg" | sed 's/\.gpg$//' | while read -r line; do
            echo -e "  ${WHITE}○${NC} ${GREEN}$line${NC}"
        done
    fi
    
    echo -e "${CYAN}-------------------------------${NC}"
    echo -ne "${YELLOW}Press Enter...${NC}"; read
}

# ------------------------------------------------------------------------------
# Trigger security lockdown after failed attempts
# ------------------------------------------------------------------------------

trigger_lockdown() {
    clear
    
    for i in {1..5}; do
        echo -e "${RED}### PICOPI SECURITY BREACH ###${NC}"
        sleep 0.2 && clear && sleep 0.1
    done
    
    echo -e "${YELLOW}PICOPI locked for 30 seconds...${NC}"
    for ((i=30; i>0; i--)); do
        echo -ne "${RED}LOCKED: $i seconds...${NC}\r"
        sleep 1
    done
    
    FAIL_COUNT=0
    echo -e "\n${GREEN}PICOPI reset.${NC}"
    sleep 2
}

# ------------------------------------------------------------------------------
# View recent access logs
# ------------------------------------------------------------------------------

view_logs() {
    clear
    echo -e "${BLUE}--- PICOPI: AUDIT LOGS ---${NC}"
    
    [ -f "$VAULT_DIR/.vault_log" ] && tail -n 15 "$VAULT_DIR/.vault_log" || echo "No logs found."
    
    echo -ne "\n${YELLOW}Press Enter...${NC}"; read
}

# ==============================================================================
# STARTUP SEQUENCE
# ==============================================================================

show_splash
echo -e "${GREEN}Initializing PICOPI Environment...${NC}"
sleep 0.5
cd "$VAULT_DIR" && git pull origin main &>/dev/null && cd - >/dev/null

# ==============================================================================
# MAIN MENU LOOP
# ==============================================================================

while true; do
    check_sync_status
    clear
    
    # Display main menu
    echo -e "${CYAN}┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${BLUE}🔐 PICOPI SYSTEM${NC}     Status: ${SYNC_STATUS}   ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}1.${NC} ➕ Add New Password                ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}2.${NC} 🔑 Retrieve Password               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}3.${NC} 🎲 Generate Strong Pass            ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}4.${NC} 📂 List All Vaults                 ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}5.${NC} 📜 View Security Logs              ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}6.${NC} 🔄 Force Cloud Sync (Git)          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${YELLOW}7.${NC} 🚪 Secure Exit                     ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────┘${NC}"
    echo -ne "${CYAN}Selection » ${NC}"
    read choice

    # Process user selection
    case $choice in
        1) add_password ;;
        2) get_password ;;
        3) gen_password ; echo -e "\n${YELLOW}Press Enter...${NC}" ; read ;;
        4) list_passwords ;;
        5) view_logs ;;
        6) echo -e "${CYAN}Syncing PICOPI...${NC}"; cd "$VAULT_DIR" && git pull && git add . && git commit -m "Manual Sync" && git push && sleep 1 ;;
        7) typewriter "${RED}Locking PICOPI session...${NC}"; sleep 1; clear; exit 0 ;;
        *) echo -e "${RED}Invalid!${NC}"; sleep 1 ;;
    esac
done