#!/usr/bin/env bats

status=99

@test "starts mongodb" {
    # should return a 0 status code if mongodb is running
    if [ -e /etc/init.d/mongodb ]; then
        run /etc/init.d/mongodb status
        [ "$status" -eq 0 ]
    elif [ -e /etc/init.d/mongod ]; then
        run /etc/init.d/mongod status
        [ "$status" -eq 0 ]
    elif [ -e /etc/init/mongod ]; then
        run /usr/sbin/service mongod status
        [ "$status" -eq 0 ]
    elif [ -e /lib/systemd/system/mongod.service ]; then
        run /bin/systemctl status mongod.service
        [ "$status" -eq 0 ]
    fi

    # this catches if neither init files are present
    [ "$status" -eq 0 ]
}
