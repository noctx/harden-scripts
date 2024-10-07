#!/bin/bash
# Accept FTP only for IPv4
iptables -4 -A INPUT -p tcp --dport 21 --syn -m conntrack --ctstate NEW -j ACCEPT
