#!/bin/bash

#Flush
iptables -F
iptables -t nat -F
iptables -X

#Drop
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
#IDA Floating Licence
/sbin/iptables -A OUTPUT -p udp --dport 6200 -j DROP
#IDA Named Licence
/sbin/iptables -A OUTPUT -p udp --dport 23945 -j DROP
iptables -A INPUT -i lo -j ACCEPT
#Cuckoo
iptables -A INPUT -i vboxnet0 -s 192.168.56.101 -p icmp -j ACCEPT
iptables -A INPUT -i vboxnet0 -s 192.168.56.101 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i vboxnet0 -s 192.168.56.101 -p tcp --dport 443 -j ACCEPT

iptables -A INPUT -p tcp --dport 443 -j ACCEPT
#Autoriser les connexions initialisées
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

#TOR
iptables -A INPUT -i vboxnet0 -p tcp --dport 9040 -j ACCEPT
iptables -A INPUT -i lo -p tcp --dport 9050 -j ACCEPT
iptables -A INPUT -i vboxnet0 -p udp -s 192.168.56.101 ! --dport 53 -j DROP
iptables -t nat -A PREROUTING -i vboxnet0 -p udp -s 192.168.56.101 --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i vboxnet0 -p tcp -s 192.168.56.101 --syn ! --dport 2042 -j REDIRECT --to-ports 9040

#Ubuntu Local
iptables -A OUTPUT -s 192.168.56.101 -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -s 192.168.56.101 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -P OUTPUT ACCEPT

