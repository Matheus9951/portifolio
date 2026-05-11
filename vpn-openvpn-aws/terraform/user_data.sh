#!/bin/bash
# ============================================================
# Script de inicialização do servidor OpenVPN
# Executado automaticamente no primeiro boot da EC2
# ============================================================

set -euo pipefail

# Variáveis injetadas pelo Terraform
VPN_NETWORK="${vpn_network}"   # ex: 10.8.0.0
VPC_CIDR="${vpc_cidr}"         # ex: 10.0.0.0/16

# ── Atualizar sistema e instalar dependências ─────────────────
yum update -y
yum install -y openvpn easy-rsa iptables-services

# ── Habilitar IP forwarding ───────────────────────────────────
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# ── Configurar PKI com Easy-RSA ───────────────────────────────
EASYRSA_DIR="/etc/openvpn/easy-rsa"
mkdir -p $EASYRSA_DIR
cp -r /usr/share/easy-rsa/3/* $EASYRSA_DIR/
cd $EASYRSA_DIR

# Inicializar PKI
./easyrsa init-pki

# Gerar CA (sem senha para automação)
echo "VPN-CA" | ./easyrsa build-ca nopass

# Gerar certificado do servidor
./easyrsa gen-req server nopass
echo "yes" | ./easyrsa sign-req server server

# Gerar parâmetros Diffie-Hellman
./easyrsa gen-dh

# Gerar chave TLS adicional (proteção contra ataques DoS)
openvpn --genkey secret /etc/openvpn/ta.key

# ── Configurar servidor OpenVPN ───────────────────────────────
cat > /etc/openvpn/server.conf << EOF
port 1194
proto udp
dev tun

ca   /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key  /etc/openvpn/easy-rsa/pki/private/server.key
dh   /etc/openvpn/easy-rsa/pki/dh.pem

# Rede VPN
server $VPN_NETWORK 255.255.255.0

# Roteamento — empurrar rota da VPC para os clientes
push "route $(echo $VPC_CIDR | cut -d'/' -f1) 255.255.0.0"
push "dhcp-option DNS 8.8.8.8"

# Segurança
tls-auth /etc/openvpn/ta.key 0
cipher AES-256-GCM
auth SHA256
tls-version-min 1.2

# Manter conexão ativa
keepalive 10 120
persist-key
persist-tun

# Logs
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3

# Máximo de clientes
max-clients 50
EOF

# ── Configurar NAT para acesso à VPC ─────────────────────────
INTERFACE=$(ip route | grep default | awk '{print $5}')
iptables -t nat -A POSTROUTING -s "$VPN_NETWORK/24" -o "$INTERFACE" -j MASQUERADE
service iptables save

# ── Iniciar e habilitar OpenVPN ───────────────────────────────
systemctl enable openvpn@server
systemctl start openvpn@server

echo "✅ OpenVPN configurado e iniciado com sucesso!"
