#!/bin/bash

echo "> Allowing GPG search on port 11371"

iptables -A OUTPUT -p tcp --dport 11371 -m conntrack --ctstate NEW -j ACCEPT

echo "> Done"
