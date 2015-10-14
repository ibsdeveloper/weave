#! /bin/bash

. ./config.sh

start_suite "Abuse of 'start' operation"

weave_on $HOST1 launch
docker_bridge_ip=$(weave_on $HOST1 docker-bridge-ip)
proxy_start_container $HOST1 --name=c1

# Start c2 with a sneaky HostConfig
proxy docker_on $HOST1 create --name=c2 $SMALL_IMAGE $CHECK_ETHWE_UP
proxy docker_api_on $HOST1 POST /containers/c2/start '{"NetworkMode": "container:c1"}'
docker_on $HOST1 attach c2 >/dev/null || true # Wait for container to exit
assert "docker_on $HOST1 inspect -f '{{.State.Running}} {{.State.ExitCode}} {{.HostConfig.Dns}}' c2" "false 0 [$docker_bridge_ip]"

# Start c3 with HostConfig having empty binds and null dns/networking settings
proxy docker_on $HOST1 create --name=c3 -v /tmp:/hosttmp $SMALL_IMAGE $CHECK_ETHWE_UP
proxy docker_api_on $HOST1 POST /containers/c3/start '{"Binds":[],"Dns":null,"DnsSearch":null,"ExtraHosts":null,"VolumesFrom":null,"Devices":null,"NetworkMode":""}'
docker_on $HOST1 attach c3 >/dev/null || true # Wait for container to exit
assert "docker_on $HOST1 inspect -f '{{.State.Running}} {{.State.ExitCode}} {{.HostConfig.Dns}}' c3" "false 0 [$docker_bridge_ip]"

# Start c4 with an 'null' HostConfig
proxy docker_on $HOST1 create --name=c4 $SMALL_IMAGE echo foo
assert_raises "proxy docker_api_on $HOST1 POST /containers/c4/start 'null'"

end_suite
