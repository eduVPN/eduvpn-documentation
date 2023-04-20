# Source Routing

**NOTE**: this is a WORK IN PROGRESS!

There are a number of situations to do _source routing_ or _policy routing_.

1. You already have a dedicated NAT router, i.e. CGNAT ("Carrier Grade NAT");
2. You have a (layer 2) connection to the target location from your VPN box 
   where the VPN traffic needs to be sent over, i.e. when the VPN server is
   located outside the network where the traffic needs to go.

These require that you do not send the traffic from the VPN clients over the 
VPN server's default gateway.

We created a physical test setup similar to what you see below.

## Test Setup

```
                           Internet
                               ^
                               |
                          .--------.
                          | Router |
                          '--------'
                               ^ 192.168.178.1
                               |
     192.168.178.10            |
      .--------.          .--------.
      | Client |--------->| Switch |<-------------------------.
      '--------'          '--------'                          |
  VPN IP: 10.10.10.2           ^                              |
                               |                              |
                               |                              |
          192.168.178.2 (eth0) |                192.168.178.3 |
                        .------------.                     .-----.
                        | VPN Server |-------------------->| NAT |
                        '------------'                     '-----'
                10.10.10.1     192.168.1.100      192.168.1.1
                (wg0/tun0)	   (eth1)
```

## Assumptions

1. Your VPN clients get IP addresses assigned from the `10.10.10.0/24` and 
   `fd00:4242:4242:4242::/64` pools, the VPN server has `10.10.10.1` and
   `fd00:4242:4242:4242::1` on the `tun0` or `wg0` device;
2. A network connection between the VPN box and the NAT router exists through
   another interface, e.g. `eth1`:
    - the VPN box has the IP addresses `192.168.1.100` and 
      `fd00:1010:1010:1010::100` on this network;
    - the remote NAT router has the IP addresses `192.168.1.1` and 
      `fd00:1010:1010:1010::1` on this network;
3. You installed the VPN server using the deployment script 
   `deploy_${DIST}.sh`.
4. The network where you route your client traffic over has _static routes_ 
   back to your VPN server:
    - There is an IPv4 static route for `10.10.10.0/24` via `192.168.1.100`;
    - There is an IPv6 static route for `fd00:4242:4242:4242::/64` via 
      `fd00:1010:1010:1010::100`;

## Configuration

We'll need to add a new routing table. You can do this by adding a line in 
`/etc/iproute2/rt_tables`:

```
200     vpn
```

Next, we'll add some routing rules manually in order to test whether we have
the correct configuration:

```
$ sudo ip -4 rule add to 10.10.10.0/24 lookup main
$ sudo ip -4 rule add from 10.10.10.0/24 lookup vpn
$ sudo ip -6 rule add to fd00:4242:4242:4242::/64 lookup main
$ sudo ip -6 rule add from fd00:4242:4242:4242::/64 lookup vpn
```

The `to` rules are needed to make sure traffic between VPN clients uses the 
`main` table so traffic between VPN clients remains possible, if this is 
allowed by the firewall.

Next, we'll add the routes:

```
$ sudo ip -4 ro add default via 192.168.1.1 table vpn
$ sudo ip -6 ro add default via fd00:1010:1010:1010::1 table vpn
```

## Permanent Configuration

The above instructions are meant for testing, now let's make them permanent.

### Enterprise Linux / Fedora

Install the required _dependency_:

```bash
$ sudo dnf -y install NetworkManager-dispatcher-routing-rules
```

Make the _rules_ and _routes_ permanent:

```
# echo 'to 10.10.10.0/24 lookup main' >/etc/sysconfig/network-scripts/rule-eth1
# echo 'from 10.10.10.0/24 lookup vpn' >/etc/sysconfig/network-scripts/rule-eth1
# echo 'to fd00:4242:4242:4242::/64 lookup main' >/etc/sysconfig/network-scripts/rule6-eth1
# echo 'from fd00:4242:4242:4242::/64 lookup vpn' >/etc/sysconfig/network-scripts/rule6-eth1
# echo 'default via 192.168.1.1 table vpn' > /etc/sysconfig/network-scripts/route-eth1
# echo 'default via fd00:1010:1010:1010::1 table vpn' > /etc/sysconfig/network-scripts/route6-eth1
```

### Ubuntu

We'll need to add the routing in the [Netplan](https://netplan.io/) 
configuration file `/etc/netplan/my-network.yaml`, e.g.:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.178.2/24
      nameservers:
        addresses:
          - 9.9.9.9
          - 2620:fe::9
        search:
          - example.org
      routes:
        - to: 0.0.0.0/0
          via: 192.168.178.1
      routing-policy:
        - from: 10.10.10.0/24
          table: 200
        - from: fd00:4242:4242:4242::/64
          table: 200
    eth1:
      addresses:
        - 192.168.1.100/24
        - fd00:1010:1010:1010::100/64
      routes:
        - to: default
          via: 192.168.1.1
          table: 200
        - to: default
          via: fd00:1010:1010:1010::1
          table: 200
```

You can find more information in the official documentation 
[here](https://netplan.readthedocs.io/en/stable/examples/#configuring-source-routing).

In order to apply the changes, run:

```bash
$ netplan generate 
$ netplan apply
```

## Troubleshooting

It is smart to reboot your system to see if all comes up as expected:

```bash
$ ip -4 rule show table vpn
32765:	from 10.10.10.0/24 lookup vpn 
$ ip -4 ro show table vpn
default via 192.168.1.1 dev eth1 
$ ip -6 rule show table vpn
32765:	from fd00:4242:4242:4242::/64 lookup vpn 
$ ip -6 ro show table vpn
default via fd00:1010:1010:1010::1 dev eth1 metric 1024 pref medium
```

## Firewall

See the [firewall](FIREWALL.md) documentation on how to update your firewall
as needed.
