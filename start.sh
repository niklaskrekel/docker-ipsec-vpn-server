#!/bin/sh
sudo modprobe af_key

config_path=$(dirname $PWD)/vpn
echo "Saving configurations in $config_path"


mkdir -p $config_path/ipsec.d
mkdir -p $config_path/ppp
touch $config_path/ipsec.d/passwd
touch $config_path/ppp/chap-secrets
touch $config_path/ipsec.secrets

docker-compose up -d vpn
success=$?
[ $success -eq 0 ] && echo "Started service vpn through docker compose" && exit 0

EXTRA_ARGS=
if [ -f $PWD/pre-up.sh ]; then
    EXTRA_ARGS="-v $PWD/pre-up.sh:/pre-up.sh"
fi

docker run \
    --name ipsec-vpn-server \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v /lib/modules:/lib/modules:ro \
    -v "$config_path/ppp/chap-secrets:/etc/ppp/chap-secrets" \
    -v "$config_path/ipsec.d/passwd:/etc/ipsec.d/passwd" \
    -v "$config_path/ipsec.secrets:/etc/ipsec.secrets" \
    $EXTRA_ARGS \
    -d --privileged \
    --restart=always \
    niklas/docker-ipsec-vpn-server
