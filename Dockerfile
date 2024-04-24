# Pull ubuntu image
FROM ubuntu:22.04

# Set environment variables
ENV DISPLAY=:1 \
    WINEARCH=win32 \
    WINEPREFIX="/wine" \
    DEBIAN_FRONTEND=noninteractive \
    PUID=0 \
    PGID=0

# Install temporary packages
RUN apt-get update && \
    apt-get install -y wget curl software-properties-common apt-transport-https cabextract xvfb winbind

# Enable 32-bit
RUN dpkg --add-architecture i386 && apt-get update

# Install wine and necessary dependencies
RUN apt-get install -y wine32 winetricks

# Configure wine prefix
# WINEDLLOVERRIDES is required so wine doesn't ask any questions during setup
RUN Xvfb :1 -screen 0 320x240x24 & \
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u && \
    wineserver -w && \
    winetricks -q vcrun2012

#Install libvulkan and libgll
RUN apt-get install -y libvulkan1:i386 && \
    apt-get install -y libgl1:i386

# Cleanup
RUN apt-get remove -y wget software-properties-common apt-transport-https cabextract && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf .cache/

# Add the default configuration files
ADD defaults defaults

# Set volumes
VOLUME /game /scripts /config
