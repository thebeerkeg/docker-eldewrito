<img src="http://i.imgur.com/IkTrjna.png" width="190" height="164" align="right"/>

# ElDewrito dedicated server dockerized

## About

This is a Dockerfile for running the ElDewrito server under Linux. The container uses Wine to run the Windows application and xvfb to create a virtual desktop.

The container is running 100% headless - no GUI is required for installation, execution or configuration.

The game files are required in order to start this container. They are not bundled within the container and you will have to provide them.

## Usage

Clone this project and edit the `docker-compose.yaml` file according to your preferences or leave as is.

With docker-compose installed, run the following command:

    docker-compose up -d

If no configuration exists in the game directory, a [default configuration](defaults) file will be automatically generated. It's advisable to close the server after the default configuration is generated, allowing you to edit the `dewrito_prefs.cfg` file before restarting.

## Tutorial (for Ubuntu hosts)

1. Prepare a Ubuntu host.
2. Install Docker for Ubuntu by following [this guide](https://docs.docker.com/install/linux/docker-ce/ubuntu/).
3. Make sure Docker is working by running `docker -v`.
4. Install docker-compose with `sudo apt-get install docker-compose`.
5. Clone the git repository.
6. (OPIONAL) Edit the `docker-compose.yaml` file: `nano docker-compose.yml`.
7. Create the `eldewrito` folder: `sudo mkdir eldewrito`.
8. Copy all your ElDewrito game files over to the `eldewrito` folder. So that `eldewrito/eldorado.exe` exists.
9. Run `docker-compose up -d`.

You're done. Your container will now be running and you can check if it is working by visting http://server_ip:11775 in your browser.

You can use `docker ps` to view running containers.

You can use `docker-compose logs` to view the logs inside of the container.

## Configuration

### Ports

| Port       | Protocol | Description |
|------------|----------|-------------|
| `11774` | UDP | Used for the game traffic |
| `11775` | TCP | Runs the HTTP server used for communication with clients |
| `11776` | TCP | Used for controlling the server via RCon |
| `11777` | TCP | VoIP |

### Volumes

| Path       | Description                                                                         | Required |
|------------|-------------------------------------------------------------------------------------|----------|
| `/game`    | Has to be mounted with the ElDewrito game files in place.                           | Yes      |
| `/scripts` | Contains start.sh script to start the eldorado.exe.                                 | Yes      |
| `/logs`    | Contains the dorito.log and chat.log if the default configuration is used.          | No       |
| `/config`  | Links to the folder that contains your `dewrito_prefs.cfg` in the eldewrito folder. | Yes      |

### Environment variables

| Variable  | Description | Default  | Required |
|-----------|-------------|----------|----------|
| `RUN_AS_USER` | Set to true or 1 to run as user instead of root. | - | No |
| `PUID` | The user that the game server should be started as. You also need to set RUN_AS_USER. | 1000 | No |
| `PGID` | The group that should own the game, config and logs directories. You also need to set RUN_AS_USER. | 1000 | No |
| `INSTANCE_ID` | Starts the server in multi instance mode when set. Uses the configuration from /config/dewrito_prefs.cfg. Do not edit any config in your game directory in this mode, they will not be used. Instance identifier must be unique. | - | No |
| `SKIP_CHOWN` | Skips the chowning on container startup. Speeds up container startup but requires proper directory permissions. | - | No |
| `WAIT_ON_EXIT` | Set to true or 1 to wait before the container exits. | - | No |
| `WINE_DEBUG` | Set to true or 1 to get verbose output from Wine. | - | No |
