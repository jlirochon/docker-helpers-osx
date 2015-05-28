# docker-helpers-osx

A small script which simplify NFS file sharing between OS X and a Docker host running in a local virtual machine.

When you start your Docker host, it automatically adds your shared folder to your NFS exports, and automatically mount your it from inside your Docker host.

When you stop your Docker host, it automatically removes the shared folder from your NFS exports.

Finally it provides shortcut to docker commands.

## Commands

* `d` is a shortcut for `docker`.
* `dm` is a shortcut for `docker-machine`
* `dm start` will start the Docker host
* `dm stop` will stop the Docker host
* `dm restart` will stop and start again

## Installation

* clone this repository somewhere, for example inside a `~/bin` folder.
* put the following lines in your `~/.profile` (edit to your convenance):

    DOCKER_HELPERS_OSX_MACHINE="dev"
    DOCKER_HELPERS_OSX_NFS_EXPORT="/Users/julien/Workspace"
    source ~/bin/docker-helpers-osx/docker-helpers-osx.bash

* reload your `~/.profile` by issuing a `source ~/.profile` command.
