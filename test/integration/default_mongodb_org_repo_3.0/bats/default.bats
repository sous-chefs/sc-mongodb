#!/usr/bin/env bats

@test "starts mongodb" {
    if [ -e /etc/init.d/mongod ]; then
        run /etc/init.d/mongod status
        [ "$status" -eq 0 ]
    fi

    # this catches if neither init files are present
    [ "$status" -eq 0 ]
}

@test "mongod is 3.0" {
    if [ -e /usr/bin/mongod ]; then
        run /usr/bin/mongod --version
        [ "${lines[0]}" = "db version v3.0.9" ]
    fi

    # this catches if the init file isn't present
    [ "$status" -eq 0 ]
}
