###############################################################################
# 4. HOST SPECIFIC NAT RULES                                                  #
#                                                                             #
# Uncomment this section if you want to use NAT table, e.g. for port          #
# forwarding, redirect, masquerade... If you want to load this section only   #
# for IPv4 and ignore for IPv6, use ip6tables-restore with -T filter.         #
###############################################################################

#*nat

# Base policy
#:PREROUTING ACCEPT [0:0]
#:POSTROUTING ACCEPT [0:0]
#:OUTPUT ACCEPT [0:0]

# Redirect port 21 to local port 2121
#-A PREROUTING -i eth0 -p tcp --dport 21 -j REDIRECT --to-port 2121

# Forward port 8080 to port 80 on host 192.168.1.10
#-4 -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.10:80

#COMMIT
