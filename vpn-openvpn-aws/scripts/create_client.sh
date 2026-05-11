#!/bin/bash
# ============================================================
# create_client.sh — Gera certificado e config para novo cliente VPN
# Uso: ./create_client.sh <nome-do-cliente>
# ============================================================

set -euo pipefail

CLIENT_NAME="${1:?Informe o nome do cliente: ./create_client.sh meu-usuario}"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
OUTPUT_DIR="/tmp/vpn-clients/$CLIENT_NAME"
SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

mkdir -p "$OUTPUT_DIR"

cd "$EASYRSA_DIR"

# Gerar certificado do cliente
./easyrsa gen-req "$CLIENT_NAME" nopass
echo "yes" | ./easyrsa sign-req client "$CLIENT_NAME"

# Gerar arquivo .ovpn completo (tudo embutido)
cat > "$OUTPUT_DIR/$CLIENT_NAME.ovpn" << EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3

<ca>
$(cat $EASYRSA_DIR/pki/ca.crt)
</ca>

<cert>
$(cat $EASYRSA_DIR/pki/issued/$CLIENT_NAME.crt)
</cert>

<key>
$(cat $EASYRSA_DIR/pki/private/$CLIENT_NAME.key)
</key>

<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

echo "✅ Configuração gerada: $OUTPUT_DIR/$CLIENT_NAME.ovpn"
echo "📋 Envie este arquivo ao usuário de forma segura (ex: AWS Secrets Manager ou S3 privado)"
