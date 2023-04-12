#!/bin/bash
######################################################################################################################################

########## Functions

spawn() {
  export PODMAN_FLEET_NAME="$1"
  export PODMAN_FLEET_N=$2

  ########## General
  USER=user
  PASS=pass

  DISTRO=debian
  SETUP_INSTALL="apt update && apt full-upgrade -y && apt install -y openssh-server tmux iproute2"

  ########## Placeholder for additional image customizations
  SETUP_OTHER="echo"

  ########## I\O
  INPUT_VOLUME_NAME=input
  OUTPUT_VOLUME_NAME=output

  ########## Container setup
  podman pull $DISTRO

cat > Containerfile <<EOF
FROM $DISTRO
RUN \ 
  echo alias ll=\'ls -l\' >> /root/.bashrc ; \
  useradd $USER -s /bin/bash -m && \
  echo $USER:$PASS | chpasswd && \
  mkdir /$INPUT_VOLUME_NAME && \
  mkdir /$OUTPUT_VOLUME_NAME && \
  chown $USER:$USER /$INPUT_VOLUME_NAME /$OUTPUT_VOLUME_NAME && \
  chmod 770 /$INPUT_VOLUME_NAME /$OUTPUT_VOLUME_NAME && \
  $SETUP_INSTALL && \
  $SETUP_OTHER 
EOF



  ########## Image
  podman build -t $PODMAN_FLEET_NAME .

  ########## Network
  podman network create $PODMAN_FLEET_NAME --subnet 10.70.0.0/16


  ########## Folders
  for i in $(seq 1 $PODMAN_FLEET_N); do
    mkdir -p "DATA/$PODMAN_FLEET_NAME/$OUTPUT_VOLUME_NAME-$i"
    mkdir -p "DATA/$PODMAN_FLEET_NAME/$INPUT_VOLUME_NAME-$i"
  done


  ########## Container start
  for i in $(seq 1 $PODMAN_FLEET_N); do
    podman run -d \
    --name $PODMAN_FLEET_NAME-$i \
    --hostname $PODMAN_FLEET_NAME-$i \
    -v "$PWD/DATA/$PODMAN_FLEET_NAME/$INPUT_VOLUME_NAME-$i:/$INPUT_VOLUME_NAME:Z" \
    -v "$PWD/DATA/$PODMAN_FLEET_NAME/$OUTPUT_VOLUME_NAME-$i:/$OUTPUT_VOLUME_NAME:Z" \
    --ip 10.70.0.$((i+10)) \
    --network "$PODMAN_FLEET_NAME" localhost/"$PODMAN_FLEET_NAME" \
    sleep infinity &

    echo "HOST: "$PODMAN_FLEET_NAME"-$i \\ IP: 10.70.0.$((i+10))"
  done

  ######### Wait until all containers are up before attempting attach

  counter=0

  while [[ $(podman ps | grep -v CREATED | wc -l) != $PODMAN_FLEET_N ]]; do
    sleep 1
    counter=$((counter+1))

    echo "Waiting for containers: $(podman ps | grep -v CREATED | wc -l) / $PODMAN_FLEET_N"

    if [[ counter -gt 30 ]] ; then 
      echo "Timed out when waiting for containers (more than 30 seconds elapsed). Check manually with podman ps -a"
    fi

  done

  attach

}


attach() {
  ######### Tmux \\ "Ctrl+B N or P — Move to the next or previous window."
  tmux new-session -s $PODMAN_FLEET_NAME -d "watch -n 2 podman stats --no-stream"
  tmux split-window -v -t $PODMAN_FLEET_NAME:0 "watch -n 2 podman ps"

  for i in $(seq 1 $PODMAN_FLEET_N); do
    tmux new-window -t $PODMAN_FLEET_NAME:$i -n $PODMAN_FLEET_NAME-$i "podman exec -it $PODMAN_FLEET_NAME-$i /bin/bash"
  done

  tmux attach-session -t $PODMAN_FLEET_NAME
}


show_error() {
  echo "Unknown option $1. Use -h or --help for usage"
}

show_help() {
cat << EOF
Description:
    Basic script that spawns N customized podman containers and attaches tmux to them

Usage: 
    podman-fleet.sh [OPTIONS] [ARGUMENTS]

Options:

    spawn FLEET_NAME N
        Creates N containers with name scheme FLEET_NAME, which will also be used for volumes and network.

    stop
        Stops all the containers

    start
        Starts all the containers again

    cleanup
        Stops and removes all the containers, along with the customized container image and the newly created network

    attach FLEET_NAME
        Attach (through tmux) to the container terminals. 
        Assumed by default but available as standalone option if you need to re-create the tmux connections.

    -h, --help, help
        Print this help message and exit.



Examples:
    sh podman-fleet.sh spawn myfleet 8
        Spawns 8 containers with naming scheme 'myfleet-N' and uses tmux to attach to all of them

    sh podman-fleet.sh stop
    sh podman-fleet.sh start
    sh podman-fleet.sh cleanup
    sh podman-fleet.sh attach myfleet


EOF
}



cleanup() {
  echo cleanup
  # podman network rm ...
  # podman image rm ... 
  # podman rm ...

  clean_vars
  
}

clean_vars() {
    unset PODMAN_FLEET_NAME
    unset PODMAN_FLEET_N
}


######### Main section

while [[ $# -gt 0 ]]; do
    case $1 in
        spawn) spawn "$2" "$3"; exit 0 ;;
        #start) start; exit 0 ;;
        #stop) stop; exit 0 ;;
        #attach) attach; exit 0 ;;
        #cleanup) cleanup; exit 0 ;;
        -h|--help) show_help; exit 0 ;;
        *) show_error "$1"; exit 0 ;;
    esac

    shift

done


exit 0