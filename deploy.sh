#!/bin/bash
set -e

SSH_KEY="$HOME/.ssh/id_rsa"
OPENRC_FILE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --key)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --key requiere una ruta como argumento."
                exit 1
            fi
            SSH_KEY="$2"
            shift
            ;;
        -h|--help) 
            echo "Uso: $0 <archivo-openrc.sh> [--key <ruta-clave-ssh>]"
            echo "Ejemplo: $0 ~/admin-openrc.sh --key ~/.ssh/deploy_key"
            exit 0
            ;;
        *) 
            if [ -z "$OPENRC_FILE" ]; then
                OPENRC_FILE="$1"
            else
                echo "Argumento desconocido: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

if [ -z "$OPENRC_FILE" ]; then
    echo "Error: Tienes que pasar el archivo openrc.sh de OpenStack."
    echo "Uso: $0 <archivo-openrc.sh> [--key <ruta-clave-ssh>]"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo ">> No hay clave SSH en: $SSH_KEY"
    echo ">> Generando un par nuevo (Ed25519)..."
    
    mkdir -p "$(dirname "$SSH_KEY")"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -q
    
    echo ">> [OK] Claves creadas:"
    echo "   - Privada: $SSH_KEY"
    echo "   - Publica: ${SSH_KEY}.pub"
    echo ""
else
    echo ">> Usando clave SSH existente en: $SSH_KEY"
fi

echo ">> Cargando variables de entorno desde $OPENRC_FILE..."
source "$OPENRC_FILE"

echo ">> Levantando la infraestructura con Terraform..."
cd terraform
export TF_VAR_ssh_public_key_path="${SSH_KEY}.pub"
terraform init
terraform apply -auto-approve -parallelism=2
cd ..

echo ">> Configurando infraestructura con Ansible..."
cd ansible
ansible-playbook playbook.yml --private-key "$SSH_KEY"

echo ">> Infraestructura desplegada correctamente."
