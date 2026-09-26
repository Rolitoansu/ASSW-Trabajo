# ASSW - Trabajo

Despliegue de una infraestructura web segura sobre OpenStack mediante Terraform y Ansible.

> [!WARNING]
> Se debe editar [`terraform/config.json`](https://github.com/Rolitoansu/ASSW-Trabajo/blob/main/terraform/config.json) para indicar la **IP flotante del WAF**. Si no se configura, la máquina no tendrá acceso al exterior de la red privada.
>
> <img height="100" alt="Configuración de la IP flotante del WAF" src="https://github.com/user-attachments/assets/edf5b689-c306-4740-9aba-fbf88ea4b826" />

## Configuración

Se debe añadir en la raíz del proyecto el archivo `openrc` correspondiente al usuario de OpenStack.

Por ejemplo:

```text
UO295497_project-openrc.sh
```

## Ejecución

```bash
./deploy.sh UO295497_project-openrc.sh
```
