NBD_DISKS_URI=$(oc-metadata | grep "^VOLUMES_.*_EXPORT_URI" | cut -d "=" -f2 | sed 's|nbd://||g')
for ip_addr in $NBD_DISKS_URI
do
    NBD_DISK_ADDR=$(echo $ip_addr | cut -d ":" -f1)
    NBD_DISK_PORT=$(echo $ip_addr | cut -d ":" -f2)
    echo "> Allowing remote disk at $NBD_DISK_ADDR:$NBD_DISK_PORT on OUTPUT"
    iptables -A OUTPUT -p tcp -d $NBD_DISK_ADDR --dport $NBD_DISK_PORT -m conntrack --ctstate NEW -j ACCEPT
done

echo "> Done"
