#!/bin/bash

# Continue connections that are already established or related to an established connection.
echo "> Allowing RELATED and ESTABLISHED connections on INPUT"
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

echo "> Allowing ESTABLISHED connections on OUTPUT chain"
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Block remote packets claiming to be from a loopback address.
echo "> Blocking remote packets claiming to be from loopback"
iptables -A INPUT -s 127.0.0.0/8 ! -i lo -j DROP

# Don't attempt to firewall internal traffic on the loopback device.
echo "> Allowing loopback packets"
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Drop non-conforming packets, such as malformed headers, etc.
echo "> Blocking malformed packets"
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Drop all packets that are going to broadcast, multicast or anycast address.
echo "> Blocking BROADCAST,MULTICAST,ANYCAST,224.0.0.0/4 on INPUT"
#iptables -A INPUT -m addrtype --dst-type BROADCAST -j DROP
#iptables -A INPUT -m addrtype --dst-type MULTICAST -j DROP
#iptables -A INPUT -m addrtype --dst-type ANYCAST -j DROP
#iptables -A INPUT -d 224.0.0.0/4 -j DROP

#iptables -A OUTPUT -m addrtype --dst-type BROADCAST -j DROP
#iptables -A OUTPUT -m addrtype --dst-type MULTICAST -j DROP
#iptables -A OUTPUT -m addrtype --dst-type ANYCAST -j DROP
#iptables -A OUTPUT -d 224.0.0.0/4 -j DROP

# Log probable SYN scan and full connect scan
iptables -A INPUT -p tcp  -m multiport --dports 23,79 --tcp-flags ALL SYN -m limit --limit 3/m --limit-burst 5 -j LOG --log-prefix "[IPTables] SYN SCAN DETECTION"
# blacklist for three minuts
iptables -A  INPUT -p tcp  -m multiport --dports 23,79 --tcp-flags ALL SYN -m recent --name blacklist --set -j DROP

echo "> Done"
