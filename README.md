<img src="http://i.imgur.com/IkTrjna.png" width="190" height="164" align="right"/>

# ElDewrito dedicated server dockerized

## About

This is a Dockerfile for running the ElDewrito server under Linux. The container uses Wine to run the Windows application and xvfb to create a virtual desktop.

The container is running 100% headless - no GUI is required for installation, execution or configuration.

The game files are required in order to start this container. They are not bundled within the container and you will have to provide them.

## Supported

| Version | Working |
|---------|-|
| 0.7.0   | Yes |
| 0.6.x   | Untested |
| 0.5.x   | Untested |

## Usage

Clone this project and copy the `docker-compose.yaml.example` file and save it as `docker-compose.yaml`. Then edit your compose file according to your preferences or leave as is.

With docker-compose installed, run the following command:

    docker-compose up -d

If no configuration exists in the game directory, a [default configuration](defaults) file will be automatically generated. It's advisable to close the server after the default configuration is generated, allowing you to edit the `dewrito_prefs.cfg` file before restarting.

## Tutorial (for Ubuntu hosts)

1. Prepare a Ubuntu host.
2. Install Docker for Ubuntu by following [this guide](https://docs.docker.com/install/linux/docker-ce/ubuntu/).
3. Make sure Docker is working by running `docker -v`.
4. Install docker-compose with `sudo apt-get install docker-compose`.
5. Clone the git repository.
6. Copy the `docker-compose.yaml.example` and save as `docker-compose.yml`: `cp docker-compose.yaml.example docker-compose.yml` .
7. (Optional) Edit the `docker-compose.yml` file: `nano docker-compose.yml`.
8. Create the `eldewrito` folder: `sudo mkdir eldewrito`.
9. Copy all your ElDewrito game files over to the `eldewrito` folder. So that `eldewrito/eldorado.exe` exists.
10. Run `docker-compose up -d`.

You're done. Your container will now be running and you can check if it is working by visting http://server_ip:11775 in your browser.

You can use `docker ps` to view running containers.

You can use `docker-compose logs` to view the logs inside of the container.

## Extra steps for Multiple Servers

Duplicate the `eldewrito_server_1` service in your `docker-compose.yml`. Then set all of the following variables to unique values: 
- `GAME_PORT`, `PORT`, `RCON_PORT`, `SIGNAL_SERVER_PORT` and `FILE_SERVER_PORT`. Make sure to also match the ports in the `ports:` section.
- `SERVER_NAME`. Technically not required, but you don't want duplicate server names.
- `INSTANCE_ID`. This MUST be a unique value! Would recommend just using incremental numbers.
- `CHAT_LOG`. It should be a unique file path per server to avoid overwriting the same log file.
- (Optional) `VOTING_JSON_PATH`. If you want to have a different variety of maps, gamemodes and mods on each server, you need to create unique voting JSON files in your ED install directory. Example: `VOTING_JSON_PATH=data/server/voting_minigames.json`.

## Configuration

### Ports

| Port       | Protocol | Description                                              |
|------------|----------|----------------------------------------------------------|
| `11774` | UDP | Used for the game traffic                                |
| `11775` | TCP | Runs the HTTP server used for communication with clients |
| `11776` | TCP | Used for controlling the server via RCON                 |
| `11777` | TCP | VoIP                                                     |
| `11778` | TCP | File Server for mod packages                             |

### Volumes

| Path       | Description                                                                                     | Required |
|------------|-------------------------------------------------------------------------------------------------|----------|
| `/game`    | Has to be mounted with the ElDewrito game files in place.                                       | Yes      |
| `/scripts` | Contains start.sh script to start the eldorado.exe.                                             | Yes      |
| `/config`  | Links to the folder that contains your `dewrito_prefs.cfg` within the eldewrito install folder. | Yes      |

### Environment variables

| Variable             | Description                                                                                                                                                 | Default  | Required |
|----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------|
| `INSTANCE_ID`        | Starts the server in multi instance mode when set. Uses the configuration from /config/dewrito_prefs_[INSTANCE_ID].cfg. Instance identifier must be unique. | - | No |
| `ED_CFG_VERSION`     | Optional but recommended. Helps the container grab the default config for our server.                                                                       | - | No |
| `SERVER_NAME`        | Name of your server.                                                                                                                                        | - | No |
| `SERVER_HOST`        | Name of the server host that will appear in the server browser.                                                                                             | - | No |
| `RCON_PASSWORD`      | RCON password.                                                                                                                                              | - | No |
| `GAME_PORT`          | Game port.                                                                                                                                                  | - | No |
| `PORT`               | Port.                                                                                                                                                       | - | No |
| `RCON_PORT`          | RCON port.                                                                                                                                                  | - | No |
| `SIGNAL_SERVER_PORT` | VOIP port.                                                                                                                                                  | - | No |
| `FILE_SERVER_PORT`   | File server port.                                                                                                                                           | - | No |
| `VOTING_JSON_PATH`   | Set this to the file path of your `voting.json` file relative to your ED install directory. Example: `data/server/voting.json`.                             | - | No |
| `CHAT_LOG`           | Path to the chat log file. Comment this out to disable the chat log. Should be unique per server.                                                           | - | No |
| `RUN_AS_USER`        | Set to true or 1 to run as user instead of root.                                                                                                            | - | No |
| `PUID`               | The user that the game server should be started as. You also need to set RUN_AS_USER.                                                                       | 1000 | No |
| `PGID`               | The group that should own the game, config and logs directories. You also need to set RUN_AS_USER.                                                          | 1000 | No |
| `SKIP_CHOWN`         | Skips the chowning on container startup. Speeds up container startup but requires proper directory permissions.                                             | - | No |
| `WINE_DEBUG`         | Set to true or 1 to get verbose output from Wine.                                                                                                           | - | No |

### Credits

This container is based on [@DomiStyle](https://github.com/DomiStyle)'s: https://github.com/DomiStyle/docker-eldewrito
