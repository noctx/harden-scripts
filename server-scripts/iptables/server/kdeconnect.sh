#!/bin/bash

echo "> Allowing kde connect (port 1716) on OUTPUT"
iptables -A OUTPUT -p tcp --dport 1716 -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1739 -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1740 -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1741 -m conntrack --ctstate NEW -j ACCEPT
