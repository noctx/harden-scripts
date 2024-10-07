# Drop policy by default
echo "> Changing policy for INPUT,FORWARD,DROP to ACCEPT"

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "> Done"
