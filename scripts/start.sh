#!/bin/sh

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

CONFIG_FILE="dewrito_prefs${INSTANCE_ID:+_$INSTANCE_ID}.cfg"
CONFIG_FILE_LINK="/config/${CONFIG_FILE}"

echo "Initializing container for ElDewrito Dedicated Server"

# Function to create default configuration depending on path
create_default_config()
{
    echo "${YELLOW}Could not find an existing dewrito_prefs.cfg. Trying to use default.${NC}"

    sleep 5

    if [ -f "/defaults/${ED_CFG_VERSION}/dewrito_prefs.cfg" ]; then
        echo "Copying default dewrito_prefs.cfg for version: ${ED_CFG_VERSION}."
        cp "/defaults/${ED_CFG_VERSION}/dewrito_prefs.cfg" "${CONFIG_FILE_LINK}"
        echo "${YELLOW}Make sure to adjust important settings like your RCON password!${NC}"
    else
        echo "${YELLOW}ElDewrito version unknown. ${CONFIG_FILE} will be generated automatically after running. Make sure to update settings like 'Voting.SystemType'.${NC}"
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
if [ ! -f "$CONFIG_FILE_LINK" ]; then
    create_default_config
else
    echo "${GREEN}Found existing config: ${CONFIG_FILE}!${NC}"
fi

# Update server settings
sed -i "s/^UPnP.Enabled \"[^\"]*\"/UPnP.Enabled \"0\"/" "${CONFIG_FILE_LINK}"

if [ -n "${GAME_PORT}" ]; then
    sed -i "s/^Server.GamePort \"[^\"]*\"/Server.GamePort \"${GAME_PORT}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${PORT}" ]; then
    sed -i "s/^Server.Port \"[^\"]*\"/Server.Port \"${PORT}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${RCON_PORT}" ]; then
    sed -i "s/^Game.RconPort \"[^\"]*\"/Game.RconPort \"${RCON_PORT}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${SIGNAL_SERVER_PORT}" ]; then
    sed -i "s/^Server.SignalServerPort \"[^\"]*\"/Server.SignalServerPort \"${SIGNAL_SERVER_PORT}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${FILE_SERVER_PORT}" ]; then
    sed -i "s/^Server.FileServerPort \"[^\"]*\"/Server.FileServerPort \"${FILE_SERVER_PORT}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${SERVER_NAME}" ]; then
    sed -i "s/^Server.Name \"[^\"]*\"/Server.Name \"${SERVER_NAME}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${SERVER_HOST}" ]; then
    sed -i "s/^Player.Name \"[^\"]*\"/Player.Name \"${SERVER_HOST}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${RCON_PASSWORD}" ]; then
    sed -i "s/^Server.RconPassword \"[^\"]*\"/Server.RconPassword \"${RCON_PASSWORD}\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${CHAT_LOG}" ]; then
    sed -i "s|^Server.ChatLogFile \"[^\"]*\"|Server.ChatLogFile \"${CHAT_LOG}\"|" "${CONFIG_FILE_LINK}"
else
    sed -i "s/^Server.ChatLogEnabled \"[^\"]*\"/Server.ChatLogEnabled \"0\"/" "${CONFIG_FILE_LINK}"
fi

if [ -n "${VOTING_JSON_PATH}" ]; then
    sed -i "s|^Voting.JsonPath \"[^\"]*\"|Voting.JsonPath \"${VOTING_JSON_PATH}\"|" "${CONFIG_FILE_LINK}"
fi

if [ -z "${SKIP_CHOWN}" ]; then
    echo "Taking ownership of folders"
    chown -R "$PUID":"$PGID" /game /wine

    echo "Changing folder permissions"
    find /game -type d -exec chmod 775 {} \;

    echo "Changing file permissions"
    find /game -type f -exec chmod 664 {} \;
fi

# Xvfb needs cleaning because it doesn't exit cleanly
echo "Cleaning up"
rm /tmp/.X1-lock

echo "Starting virtual frame buffer"
Xvfb :1 -screen 0 320x240x24 &

echo "${GREEN}Starting dedicated server${NC}"

# DLL overrides for Wine are required to prevent issues with master server announcement
export WINEDLLOVERRIDES="winhttp,rasapi32=b,n"

if [ -n "${WINE_DEBUG}" ] || true; then
    echo "Setting wine to verbose output"
    export WINEDEBUG=warn+all
fi

if [ -z "${INSTANCE_ID}" ]; then
    su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized" $user
else
    echo "Starting instance ${INSTANCE_ID}"
    su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized -instance ${INSTANCE_ID}" $user
fi

echo "${RED}Server terminated, exiting${NC}"
