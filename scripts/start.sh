#!/bin/sh

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

config_file="/config/dewrito_prefs${INSTANCE_ID:+_$INSTANCE_ID}.cfg"

echo "Initializing container for ElDewrito Dedicated Server"

# Function to create default configuration depending on path
create_default_config()
{
    echo "${YELLOW}Could not find an existing dewrito_prefs.cfg. Trying to use default.${NC}"

    sleep 5

    if [ -f "/defaults/${ED_CFG_VERSION}/dewrito_prefs.cfg" ]; then
        echo "Copying default dewrito_prefs.cfg for version: ${ED_CFG_VERSION}."
        cp "/defaults/${ED_CFG_VERSION}/dewrito_prefs.cfg" "${config_file}"
        echo "${YELLOW}Make sure to adjust important settings like your RCON password!${NC}"
    else
        echo "${YELLOW}ElDewrito version unknown. dewrito_prefs.cfg will be generated automatically after running. Make sure to update settings like 'Voting.SystemType'.${NC}"
    fi
}

# Search for eldorado.exe in game directory
if [ ! -f "eldorado.exe" ]; then
    echo "${RED}Could not find eldorado.exe. Did you mount the game directory to /game?${NC}"

    sleep 2
    exit 1
fi

# Create user if container should run as user
if [ -z "${RUN_AS_USER}" ]; then
    echo "Running as root"
    user=root

    if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
        echo "${RED}Tried to set PUID OR PGID without setting RUN_AS_USER.${NC}"
        echo "${RED}Please set RUN_AS_USER or remove PUID & PGID from your environment variables.${NC}"

        sleep 2
        exit 40
    fi
else
    echo "Running as eldewrito"
    user=eldewrito

    if [ "$PUID" -lt 1000 ] || [ "$PUID" -gt 60000 ]; then
        echo "${RED}PUID is invalid${NC}"

        sleep 2
        exit 20
    fi

    if [ "$PGID" -lt 1000 ] || [ "$PGID" -gt 60000 ]; then
        echo "${RED}PGID is invalid${NC}"

        sleep 2
        exit 30
    fi

    if ! id -u eldewrito > /dev/null 2>&1; then
        echo "Creating user"
        useradd -u "$PUID" -m -d /tmp/home eldewrito
    fi
fi

# Copy configuration files or create default config
if [ ! -f "$config_file" ]; then
    create_default_config
else
    echo "${GREEN}Existing dewrito_prefs.cfg found!${NC}"
fi

if [ -z "${SKIP_CHOWN}" ]; then
    echo "Taking ownership of folders"
    chown -R "$PUID":"$PGID" /game /logs /wine

    echo "Changing folder permissions"
    find /game /logs -type d -exec chmod 775 {} \;

    echo "Changing file permissions"
    find /game /logs -type f -exec chmod 664 {} \;
fi

# Xvfb needs cleaning because it doesn't exit cleanly
echo "Cleaning up"
rm /tmp/.X1-lock

echo "Starting virtual frame buffer"
Xvfb :1 -screen 0 320x240x24 &

echo "${GREEN}Starting dedicated server${NC}"

# DLL overrides for Wine are required to prevent issues with master server announcement
export WINEDLLOVERRIDES="winhttp,rasapi32=n"

if [ -n "${WINE_DEBUG}" ]; then
    echo "Setting wine to verbose output"
    export WINEDEBUG=warn+all
fi

if [ -z "${INSTANCE_ID}" ]; then
    su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized" $user
else
    echo "Starting instance ${INSTANCE_ID}"
    su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized -instance ${INSTANCE_ID}" $user
fi

if [ -z "${WAIT_ON_EXIT}" ]; then
    echo "${RED}Server terminated, exiting${NC}"
else
    echo "${RED}Server terminated, waiting${NC}"
    sleep infinity
fi
