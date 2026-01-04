#!/usr/bin/env bash

# Set and check external server ip
SERVER_IP="45.12.4.211"
IP_SUBNET="192.168.55."

echo -n "Please Enter Client Name: "
read -r CLIENT_NAME
echo -n "Please Enter IP Address Number [2..255]: "
read -r CLIENT_IPNUM

# Generate private and public keys
wg genkey | tee /etc/wireguard/client/$CLIENT_NAME\.private | wg pubkey | tee /etc/wireguard/client/$CLIENT_NAME\.public
CLIENT_PRIVKEY=`cat /etc/wireguard/client/$CLIENT_NAME\.private`
CLIENT_PUBKEY=`cat /etc/wireguard/client/$CLIENT_NAME\.public`
SERVER_PUBKEY=`cat /etc/wireguard/publickey`

# Add public key to server
tee -a /etc/wireguard/wg0.conf <<EOF
[Peer]
PublicKey = $CLIENT_PUBKEY
AllowedIPs = ${IP_SUBNET}$CLIENT_IPNUM/32
EOF

# Create client config
cat > /etc/wireguard/client/$CLIENT_NAME\.conf <<EOL
[Interface]
PrivateKey = $CLIENT_PRIVKEY #<CLIENT-PRIVATE-KEY>
Address = ${IP_SUBNET}$CLIENT_IPNUM/32
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBKEY #<SERVER-PUBKEY>
Endpoint = $SERVER_IP:51810
AllowedIPs = ${IP_SUBNET}0/24
PersistentKeepalive = 30
EOL

# Remove files of clint's privatekey and publickey
rm /etc/wireguard/client/$CLIENT_NAME\.private /etc/wireguard/client/$CLIENT_NAME\.public

# Restart wg-server to apply configs
systemctl restart wg-quick@wg0.service
