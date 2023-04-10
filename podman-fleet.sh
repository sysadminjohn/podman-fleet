#!/bin/bash

########## General
N=5
FLEET_NAME=mybot

USER=user
PASS=pass

DISTRO=debian
SETUP_INSTALL="apt update && apt full-upgrade -y && apt install -y openssh-server tmux iproute2"
SETUP_OTHER="echo"


########## I\O
INPUT_VOLUME_NAME=input
OUTPUT_VOLUME_NAME=output

########## Ports
PORT_SSH="2200"

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
  $SETUP_OTHER && \
  service ssh start
EOF

########## Image
podman build -t $FLEET_NAME .

########## Network
podman network create $FLEET_NAME --subnet 10.70.0.0/16


########## Folders
for i in $(seq 1 $N); do
  mkdir -p "podman-fleet/$FLEET_NAME/$OUTPUT_VOLUME_NAME-$i"
  mkdir -p "podman-fleet/$FLEET_NAME/$INPUT_VOLUME_NAME-$i"
done


########## Container start
for i in $(seq 1 $N); do
  podman run -d \
  --name $FLEET_NAME-$i \
  --hostname $FLEET_NAME-$i \
  -p $(($PORT_SSH+$i+1)):22 \
  -v $PWD/podman-fleet/$FLEET_NAME/$INPUT_VOLUME_NAME-$i:/$INPUT_VOLUME_NAME:Z \
  -v $PWD/podman-fleet/$FLEET_NAME/$OUTPUT_VOLUME_NAME-$i:/$OUTPUT_VOLUME_NAME:Z \
  --ip 10.70.0.$((i+1)) \
  --network $FLEET_NAME localhost/$FLEET_NAME \
  sleep infinity &

  echo "HOST: $FLEET_NAME-$i \\ SSH: 10.70.0.$((i+1)):$(($PORT_SSH+$i+1))"
done

######### Wait until all containers are up
while [[ $(podman ps | grep -v CREATED | wc -l) != $N ]]; do
  sleep 1
done

######### Tmux \\ "Ctrl+B N or P — Move to the next or previous window."
tmux new-session -s $FLEET_NAME -d "podman stats"

for i in $(seq 1 $N); do
  tmux new-window -t $FLEET_NAME:$i -n $FLEET_NAME-$i "podman exec -it $FLEET_NAME-$i /bin/bash"
done

tmux attach-session -t $FLEET_NAME

