###### This is a guide for running docker-transcodeautomation on windows. It assumes some prior knowledge is had by the person reading this guide. It will provide a high level set of instructions, but shouldn't be assumed to be full step by step instructions.

- Install Ubuntu LTS from the Windows Store
- Run these commands from PowerShell and be sure to pick the version of Ubuntu LTS that was installed.
```powershell
wsl --list
wsl -s Ubuntu-<version>
```
- Install Docker Desktop
- Configure Docker Desktop to use wsl subsystem in the Docker Desktop settings
- Configure Docker Desktop to use the Ubuntu distro that was installed and set as the default distro for wsl
- Create a docker compose file. Windows drives are located at /mnt/`drive letter` in Ubuntu wsl.
- Copy the docker compose file to the home directory of the linux user you created when installing Ubuntu wsl. If you run docker-compose from windows it will not be able to mount the wsl imported windows drive mounts.
- Launch the Ubuntu terminal and use docker compose to bring the container online
```sh
cd ~
docker-compose up
```

# Transcode performance is about 40% worse in my testing with wsl. I would only recommend this container using a linux host, but it will work with wsl. 
