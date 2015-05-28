#!/bin/bash
# set -e
# set -o pipefail
DOCKER="docker"
DOCKER_MACHINE="docker-machine"
EXPORTS_FILE="/etc/exports"
BEGIN_TAG="# DOCKER-HELPERS-OSX-BEGIN"
END_TAG="# DOCKER-HELPERS-OSX-END"
NFS_OPTIONS="async,noatime,actimeo=1,nolock,vers=3,udp"


# Shortcut for docker command
# Commands are forwarded to docker
d() {
    $DOCKER "$@"
}


# Shortcut for docker-machine command
# Intercepts "start", "stop" and "restart" commands
# Other commands are forwarded to docker-machine
dm() {
  if [[ "$#" -eq 1 ]]; then
    case $1 in
      "start")
        __dm_start
        ;;
      "stop")
        __dm_stop
        ;;
      "restart")
        __dm_restart
        ;;
      *)
        $DOCKER_MACHINE "$@"
        ;;
    esac
  else
    $DOCKER_MACHINE "$@"
  fi
}


__timeout() {
  perl -e 'alarm shift; exec @ARGV' "$@"
}


# Removes previous export line from NFS exports file
__remove_nfs_export() {
  sudo sed -ie "/$BEGIN_TAG/,/$END_TAG/d" $EXPORTS_FILE
}


# Ensure the NFS exports file contains a valid export line
# $1 : exported dir (ex: "/Users/foo")
# $2 : ip address (ex: "172.16.31.197")
__replace_nfs_export() {
  __remove_nfs_export
  map_to="`id -u`:`id -g`"
  sudo bash -c "cat << EOF >> $EXPORTS_FILE
$BEGIN_TAG
\"$1\" $2 -alldirs -mapall=$map_to
$END_TAG
EOF"
  sudo nfsd update
}


# Mount NFS export from inside the machine
__mount_nfs_volume() {
  ip=`$DOCKER_MACHINE ip`
  host_ip="`echo $ip | cut -d'.' -f1-3`.1"
  __replace_nfs_export $DOCKER_HELPERS_OSX_NFS_EXPORT $ip
  $DOCKER_MACHINE ssh $DOCKER_HELPERS_OSX_MACHINE "sudo mkdir -p $DOCKER_HELPERS_OSX_NFS_EXPORT"
  $DOCKER_MACHINE ssh $DOCKER_HELPERS_OSX_MACHINE "sudo /usr/local/etc/init.d/nfs-client start"
  wait_time=1
  until $DOCKER_MACHINE ssh $DOCKER_HELPERS_OSX_MACHINE "sudo mount $host_ip:$DOCKER_HELPERS_OSX_NFS_EXPORT $DOCKER_HELPERS_OSX_NFS_EXPORT -o $NFS_OPTIONS" > /dev/null || [ $wait_time -eq 4 ]
  do
    sleep $(( wait_time++ ))
  done
}


# Do some cleanup
__cleanup() {
  __remove_nfs_export
  sudo nfsd update
  unset DOCKER_HOST
  unset DOCKER_CERT_PATH
  unset DOCKER_TLS_VERIFY
}


# inject DOCKER_* into environment
__update_env() {
  eval $($DOCKER_MACHINE env $DOCKER_HELPERS_OSX_MACHINE)
}


# Wait until /var/run/docker.pid exists on the Docker host
__wait_for_docker() {
  wait_time=1
  until $DOCKER_MACHINE ssh $DOCKER_HELPERS_OSX_MACHINE "[ -d /var/run/docker.pid ]" > /dev/null || [ $wait_time -eq 4 ]
  do
    sleep $(( wait_time++ ))
  done
}


# Start the machine and make everything usable
__dm_start() {
  $DOCKER_MACHINE start $DOCKER_HELPERS_OSX_MACHINE
  __mount_nfs_volume
  __wait_for_docker
  __update_env
}


# Stop the machine then cleanup
__dm_stop() {
  $DOCKER_MACHINE stop $DOCKER_HELPERS_OSX_MACHINE
  __cleanup
}


# Stop and start again
__dm_restart() {
  __dm_stop
  __dm_start
}
