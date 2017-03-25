SFTP server for docker
======================

## Description

This is a lightweight SFTP server in a docker container.

This image provides:
 - an alpine base image
 - SSH server
 - User creation based on env variable
 - Home directory based on env variable
 - Automatic UID detection based on home permissions
 - Ability to run in chroot
 - Extensibility through additional sh scripts (more users creation, tweak...)


## How to use

### Provided example

A full example is provided in the [docker-compose file](https://github.com/mickaelperrin/docker-sshd-server/blob/master/docker-compose.yml)

    git clone https://github.com/mickaelperrin/docker-sshd-server.git
    cd docker-sshd-server
    docker-compose up

### Generic example

    version: '2'

    services:
      # Example application container, this is where your data is.
      app:
        image: alpine:3.5
        # Simulate an application server with an endless loop.
        command: sh -c 'while true; do sleep 10; done';
        volumes:
          - ./data:/data
      # SSHD Server
      sshd:
        build: .
        image: mickaelperrin/sshd-server:latest
        environment:
          - USERNAME=sftp
          - PASSWORD=password
          # Should be the same as the volume mapping of app container
          - FOLDER=/data
          # Optional: chroot
          - CHROOT=1
        cap_add:
          # Required if you want to chroot a volume from another container
          - SYS_ADMIN
        security_opt:
          # Required if you want to chroot
          - apparmor:unconfined
        ports:
          - 22
        volumes_from:
          - app

### Configuration

Configuration is done through environment variables. 

Required:
- USERNAME: the name to be use for login.
- PASSWORD: the password to login.
- FOLDER: the home of the user (can be a volume mounted from another container like in the example).

Optionnal:
- CHROOT: if set to 1, enable chroot of user (prevent access to other folders than its home folder). Be aware, that 
currently this feature needs additionnal docker capabilities (see below).
- OWNER_ID: the uid of the user. If not set automatically grabbed from the uid of the owner of the FOLDER.

### Chroot 

If you want to run the SSH server with chroot feature, the docker image has to be run with additional capabilities.

    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined

This is due to the use of `mount --bind` in the init script.

**If someone has a better way to do, feel free to submit a pull request or a hint.**

## Disclaimer

Besides the usual disclaimer in the license, we want to specifically emphasize that the authors, and any organizations the authors are associated with, can not be held responsible for data-loss caused by possible malfunctions of Docker Magic Sync.

## License

[GPLv2](http://www.fsf.org/licensing/licenses/info/GPLv2.html) or any later GPL version.
