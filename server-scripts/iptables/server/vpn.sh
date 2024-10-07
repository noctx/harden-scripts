#!/bin/bash

echo "> Allowing VPN on port 1194"
iptables -A OUTPUT -p udp --dport 1194 -m conntrack --ctstate NEW -j ACCEPT
echo "> Done"
