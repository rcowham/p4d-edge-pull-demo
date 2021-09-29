# p4d-edge-pull-demo
Docker images for showing pull triggers on edge servers.

This configuration initialises a commit/edge setup with two containers and allows for some manual testing.

## How to use

Build and run:

    docker-compose build
    docker-compose up -d

To properly configure and create edge server with required values:

    docker exec -ti p4d-edge-pull-demo_master_1 /bin/bash
    sudo su - perforce
    ./configure_master.sh

Then if you want to test things on edge server:

    ssh replica_edge

    . /p4/common/bin/p4_vars 1
    /p4/common/bin/p4login
    p4 verify -qt //depot/Misc/...
    cat /p4/1/logs/pull.log
