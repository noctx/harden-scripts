#!/bin/bash

echo "> Allowing HTTP & HTTPS protocols on OUTPUT"
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

echo "> Allowing HTTP & HTTPS protocols on INPUT"
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT


echo "> Done"
