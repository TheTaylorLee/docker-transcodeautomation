###### This is a guide for running docker-transcodeautomation on windows. It assumes some prior knowledge is had by the person reading this guide. It will provide a high level set of instructions, but shouldn't be assumed to be a full step by step guideline.

- Install Ubuntu LTS from windows store
- Run these commands from Powershell and be srue to pick the version of ubuntu lts that was installed.
```powershell
wsl --list
wsl -s Ubuntu-<version>
```
- Install docker desktop
- Configure Docker desktop to use wsl subsystem
- Configure docker desktop to use the ubuntu distro that was installed
- Create a docker compose file. Windows drives are located at /mnt/`drive letter` in ubuntu wsl.
- Copy the docker compose file to the home directory of the linux user you created when installing ubuntu wsl. If you run docker-compose from windows it will not be able to mount the wsl imported windows drive mounts.
- Launch the ubuntu cli and use docker compose to bring the container online
```sh
cd ~
docker-compose up
```