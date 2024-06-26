#!/bin/sh

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

CONFIG_FILE="dewrito_prefs${INSTANCE_ID:+_$INSTANCE_ID}.cfg"
CONFIG_FILE_LINK="/config/${CONFIG_FILE}"

echo "Initializing container for ElDewrito Dedicated Server"

# Function to send GET request to a local URL
send_info_server_request() {
    # Sleep for a few seconds to allow eldorado.exe to start
    sleep 20

    # Send GET request to a local URL
    echo "Sending GET request to info server"
    curl -X GET "http://localhost:${PORT}"
}

# Function to create default configuration depending on path
create_default_config() {
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

update_setting() {
    setting="$1"
    value="$2"

    if [ -n "$value" ]; then
        sed -i "s|^$setting \"[^\"]*\"|$setting \"$value\"|" "$CONFIG_FILE_LINK"
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

# Update dewrito_prefs
update_setting "UPnP.Enabled" "0" # Not needed and will only error
update_setting "Game.Discord.Enable" "0"
update_setting "Server.GamePort" "$GAME_PORT"
update_setting "Server.Port" "$PORT"
update_setting "Game.RconPort" "$RCON_PORT"
update_setting "Server.SignalServerPort" "$SIGNAL_SERVER_PORT"
update_setting "Server.FileServerPort" "$FILE_SERVER_PORT"
update_setting "Server.Name" "$SERVER_NAME"
update_setting "Player.Name" "$SERVER_HOST"
update_setting "Server.Message" "$SERVER_MESSAGE"
update_setting "Server.RconPassword" "$RCON_PASSWORD"
update_setting "Voting.SystemType" "$VOTING_SYSTEM_TYPE"
update_setting "Voting.VoteTime" "$VOTING_TIME"

if [ -n "$CHAT_LOG" ]; then
    update_setting "Server.ChatLogEnabled" "1" "${CONFIG_FILE_LINK}"
    update_setting "Server.ChatLogFile" "$CHAT_LOG" "${CONFIG_FILE_LINK}"
else
    update_setting "Server.ChatLogEnabled" "0" "${CONFIG_FILE_LINK}"
fi

update_setting "Voting.JsonPath" "$VOTING_JSON_PATH" "${CONFIG_FILE_LINK}"

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

if [ -n "${WINE_DEBUG}" ]; then
    echo "Setting wine to verbose output"
    export WINEDEBUG=warn+all
fi

# Servers do not automatically announce to the master servers for some reason when run
# inside a Docker container. Visiting the server's info server somehow fixes this..
send_info_server_request &

if [ -z "${INSTANCE_ID}" ]; then
    su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized" $user
else
    echo "Starting instance ${INSTANCE_ID}"
    su -c "wine eldorado.exe -launcher -dedicated -window -height 200 -width 200 -minimized -instance ${INSTANCE_ID}" $user
fi

echo "${RED}Server terminated, exiting${NC}"
