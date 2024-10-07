#!/bin/bash
# Drop policy by default

echo "> Changing policy for INPUT,FORWARD,OUTPUT to DROP"

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "> Done"
