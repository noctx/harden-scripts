#!/bin/bash
DNS_SERVER="1.1.1.1 1.0.0.1"
for ip in $DNS_SERVER
do
echo "> Allowing DNS communication for ip '$ip'..."
iptables -A OUTPUT -p udp --sport 1024:65535 -d $ip --dport 53 -m conntrack --ctstate NEW -j ACCEPT
#iptables -A INPUT -p udp -s $ip --sport 53 --dport 1024:65535 -m conntrack --ctstate ESTABLISHED -j ACCEPT

iptables -A OUTPUT -p tcp --sport 1024:65535 -d $ip --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
#iptables -A INPUT -p tcp -s $ip --sport 53 --dport 1024:65535 -m conntrack --ctstate ESTABLISHED -j ACCEPT
done
echo "> Done"
