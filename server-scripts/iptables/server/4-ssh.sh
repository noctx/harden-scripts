#!/bin/bash


# Chain for preventing SSH brute-force attacks.
# Permits 10 new connections within 5 minutes from a single host then drops
# incomming connections from that host. Beyond a burst of 100 connections we
# log at up 1 attempt per second to prevent filling of logs.
echo "> Creating SSHBRUTE chain"
iptables -N SSHBRUTE
iptables -A SSHBRUTE -m recent --name SSH --set
iptables -A SSHBRUTE -m recent --name SSH --update --seconds 300 --hitcount 30 -m limit --limit 1/second --limit-burst 100 -j LOG --log-prefix "[IPTables] SSH BRUTEFORCE DETECTION"
iptables -A SSHBRUTE -m recent --name SSH --update --seconds 300 --hitcount 30 -j DROP
iptables -A SSHBRUTE -j ACCEPT

# Accept worldwide access to SSH and use SSHBRUTE chain for preventing
# brute-force attacks.
echo "> Allowing SSH on INPUT with SSHBRUTE chain"
iptables -A INPUT -p tcp --dport 22 --syn -m conntrack --ctstate NEW -j SSHBRUTE

echo "> Allowing SSH on OUTPUT"
iptables -A OUTPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

echo "> Done"
