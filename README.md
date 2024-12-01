# Stirling-PDF Desktop

Single file installer script for the awesome [Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF) tool for desktop linux. With menu icon and everything.

This script installs Stirling-PDF as a docker or podman image. Then creates a runner script in `~/.local/bin/`. If it's not already running, the runner script runs the container and opens the Stirling-PDF Web UI in the default browser. Container keeps running in the background until manually stopped. To stop the container use `[docker|podman] stop <container_name>`

Installer also creates a desktop menu icon by creating a .desktop file in `~/.local/share/applications/`. It downloads the necessary icon image from Stirling-PDF github repo and copies it to user's icons directory.
