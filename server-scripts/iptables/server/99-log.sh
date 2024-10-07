#!/bin/bash

MAX_INPUT_LOG=5/sec

echo "> Logging dropped packets"
echo "> Use command 'journalctl -k -f' to follow"

iptables -N LOGGINGINPUT
iptables -A INPUT -j LOGGINGINPUT
# Uncomment for log limitation
# iptables -A LOGGINGINPUT -m limit --limit $MAX_INPUT_LOG -j LOG --log-prefix "[IPTables] INPUT Dropped: " --log-level 4
# iptables -A LOGGINGINPUT -j DROP
iptables -A LOGGINGINPUT -j LOG --log-prefix "[IPTables] INPUT Dropped: " --log-level 4
iptables -A LOGGINGINPUT -j DROP

iptables -N LOGGINGOUTPUT
iptables -A OUTPUT -j LOGGINGOUTPUT
# Uncomment for log limitation
# iptables -A LOGGINGOUTPUT -m limit --limit $MAX_INPUT_LOG -j LOG --log-prefix "[IPTables] OUTPUT Dropped: " --log-level 4
# iptables -A LOGGINGOUTPUT -j DROP
iptables -A LOGGINGOUTPUT -j LOG --log-prefix "[IPTables] OUTPUT Dropped: " --log-level 4
iptables -A LOGGINGOUTPUT -j DROP

echo "> Done"
