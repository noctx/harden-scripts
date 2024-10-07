#!/bin/bash

echo ">                         <"
echo ">     EREBUS STATION      <"
echo ">        HARDENING        <"
echo ">                         <"
echo ">        Starting         <"
echo ">                         <"
echo ""

./sysctl.sh
./flush.sh
./drop-policy.sh
./0-base.sh
./1-icmp.sh
./2-dns.sh
./3-http-https.sh
./4-ssh.sh
./5-whois.sh
./6-gpg.sh
./scaleway_authorize-ndb-disks.sh
./99-log.sh

echo ""
echo ">                         <"
echo ">          DONE           <"
echo ">                         <"
