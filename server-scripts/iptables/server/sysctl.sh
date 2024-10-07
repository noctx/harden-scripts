#!/bin/bash

echo "> Disabling ipv6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Enable IP spoofing protection
sysctl -w net.ipv4.conf.all.rp_filter=1

# Disable IP source routing
sysctl -w net.ipv4.conf.all.accept_source_route=0

# Ignoring broadcasts request
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
#sysctl -w net.ipv4.icmp_ignore_bogus_error_messages=1

# Make sure spoofed packets get logged
sysctl -w net.ipv4.conf.all.log_martians=1

echo "> Done"

