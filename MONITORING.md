# Monitoring

We have very minimal monitoring capability in the VPN software as of now. This 
will most likely be improved in the future if there is a need for it.

**NOTE**: `port_client_count` and `connection_list` are only available when 
using [vpn-daemon](VPN_DAEMON.md) and in JSON output format.

**NOTE**: these format is NOT "stable". If you depend on this in your scripting
be ready to update when new releases appear!

## CSV

A simple CSV format:

    $ sudo vpn-server-api-status 
    profile_id,active_connection_count,max_connection_count,percentage_in_use
    amsterdam,102,488,20

If you want to see an aggregate of the number of connected clients over all 
profiles, you can use this:

    $ sudo vpn-server-api-status | tail -n +2 | cut -d ',' -f 2 | awk '{sum+=$1}END{print sum}'

## JSON

Aggregate information:

    $ sudo vpn-server-api-status --json
    [
        {
            "profile_id": "amsterdam",
            "active_connection_count": 103,
            "max_connection_count": 488,
            "percentage_in_use": 21,
            "port_client_count": {
                "udp/1194": 15,
                "udp/1195": 27,
                "udp/1196": 21,
                "udp/1197": 17,
                "tcp/443": 9,
                "tcp/1194": 4,
                "tcp/1195": 6,
                "tcp/1196": 4
            }
        }
    ]

Show also connected VPN client information:

    $ sudo vpn-server-api-status --json --connections
    [
        {
            "profile_id": "amsterdam",
            "active_connection_count": 106,
            "max_connection_count": 488,
            "percentage_in_use": 21,
            "port_client_count": {
                "udp/1194": 16,
                "udp/1195": 26,
                "udp/1196": 21,
                "udp/1197": 19,
                "tcp/443": 9,
                "tcp/1194": 4,
                "tcp/1195": 7,
                "tcp/1196": 4
            },
            "connection_list": [
                {
                    "user_id": "john.doe",
                    "virtual_address": [
                        "192.0.2.44",
                        "2001:db8::44"
                    ]
                },
                {
                    "user_id": "jane.doe",
                    "virtual_address": [
                        "192.0.2.45",
                        "2001:db8::45"
                    ]
                },

                ...

            ]
        }
    ]
    
To show all users connected to the profile `amsterdam` you can use something
like this using the [jq](https://stedolan.github.io/jq/) tool:

    $ sudo vpn-server-api-status --json --connections | jq '.[] | select(.profile_id | contains("amsterdam")) | .connection_list | .[] .user_id'

## Alerting

There is an `--alert` flag, with optional percentage parameter, which only
lists entries for which the IP space has higher usage than the parameter. The 
default is `90` indicating `90%`. 

You can use the status command from `cron` to send out alerts when the IP space 
is about to be depleted, e.g.:

    MAILTO=admin@example.org
    */5 * * * * /usr/bin/vpn-server-api-status --alert 75

Assuming `cron` is able to mail reports this should work!
