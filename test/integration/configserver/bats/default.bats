#!/usr/bin/env bats

@test "starts configserver" {
    # should return a 0 status code if configserver is running
    run /etc/init.d/mongodb status
    [ "$status" -eq 0 ]
}
