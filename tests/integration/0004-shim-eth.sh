#!/bin/bash

source tests/libtest.sh

cleanup() {
    local ret=0
    pkill rina-echo-async
    rlite-ctl reset || ret=1
    [ "$ret" != 0 ] && return 1 || return 0
}

abort() {
    cleanup
    exit 1
}

# Create a veth pair
create_veth_pair rina.veth || exit 1

# Create a shim-eth for each end of the pair. DIF should be
# the same, but we'll cheat only for the purpose of testing.
rlite-ctl ipcp-create s0 shim-eth d0 || abort
rlite-ctl ipcp-create s1 shim-eth d1 || abort
rlite-ctl ipcp-config s0 netdev rina.veth0 || abort
rlite-ctl ipcp-config s1 netdev rina.veth1 || abort
rlite-ctl ipcp-config s1 netdev rina.veth0 && abort
rlite-ctl ipcp-config-get s0 netdev | grep "\<rina.veth0\>" || abort
rlite-ctl ipcp-config-get s0 wrongy && abort
rlite-ctl ipcp-config s0 flow-del-wait-ms 100 || abort
rlite-ctl ipcp-config s1 flow-del-wait-ms 100 || abort

# Register an application on the first shim-eth
rina-echo-async -lw -z rpinstance4 -d d0 || abort
# Run some clients on the other shim-eth
rina-echo-async -z rpinstance4 -d d1 || abort

# Cleanup
cleanup
