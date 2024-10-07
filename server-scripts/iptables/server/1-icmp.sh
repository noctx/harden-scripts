#!/bin/bash

echo "> Creating ICMPFLOOD chain"
# Chain for preventing ping flooding - up to 6 pings per second from a single
# source, again with log limiting. Also prevents us from ICMP REPLY flooding
# some victim when replying to ICMP ECHO from a spoofed source.
iptables -N ICMPFLOOD
iptables -A ICMPFLOOD -m recent --set --name ICMP --rsource
iptables -A ICMPFLOOD -m recent --update --seconds 1 --hitcount 6 --name ICMP --rsource --rttl -m limit --limit 1/sec --limit-burst 1 -j LOG --log-prefix "[IPTables] ICMP FLOODING DETECTION"
iptables -A ICMPFLOOD -m recent --update --seconds 1 --hitcount 6 --name ICMP --rsource --rttl -j DROP
iptables -A ICMPFLOOD -j ACCEPT

# Permit IMCP echo requests (ping) and use ICMPFLOOD chain for preventing ping
# flooding.
echo "> Allowing echo-request on OUTPUT"
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
echo "> Allowing echo-reply on INPUT"
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

echo "> Allowing echo-request on INPUT with ICMPFLOOD checks"
iptables -A INPUT -p icmp --icmp-type echo-request -m conntrack --ctstate NEW -j ICMPFLOOD

echo "> Allowing echo-reply on OUTPUT"
iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

echo "> Done"
