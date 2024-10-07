#!/bin/bash

echo "> Flushing all IPTables rules & chains"

iptables -F
iptables -X

echo "> Done"
