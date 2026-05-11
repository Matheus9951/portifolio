# 🔐 VPN OpenVPN na AWS com Terraform

Solução de VPN segura provisionada na AWS usando OpenVPN em EC2, totalmente automatizada com Terraform.

## 🏗️ Arquitetura

```
Usuário/Desenvolvedor
        │
        │ OpenVPN (UDP 1194)
        ▼
┌───────────────────┐
│   EC2 (OpenVPN)   │  ← Subnet Pública
│   Elastic IP      │
└────────┬──────────┘
         │ Acesso privado
         ▼
┌───────────────────┐
│  Recursos Privados│  ← Subnet Privada
│  EKS, RDS, etc.  │
└───────────────────┘
```

## 🚀 Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply

# Após o apply, pegar o IP público do servidor
terraform output vpn_server_ip

# Baixar o arquivo de configuração do cliente
terraform output -raw client_config > client.ovpn
```

## 🔐 Segurança
- Certificados PKI gerados automaticamente (Easy-RSA)
- Security Group restritivo (apenas porta 1194/UDP)
- Acesso SSH bloqueado por padrão (use SSM Session Manager)
- Logs de conexão habilitados

## 📱 Clientes suportados
- Linux: `openvpn --config client.ovpn`
- Windows: OpenVPN GUI
- macOS: Tunnelblick
- Android/iOS: OpenVPN Connect
