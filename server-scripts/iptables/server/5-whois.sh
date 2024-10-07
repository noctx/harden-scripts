#!/bin/bash

echo "> Allowing WHOIS on port 43"

iptables -A OUTPUT -p tcp --dport 43 -m conntrack --ctstate NEW -j ACCEPT

echo "> Done"
