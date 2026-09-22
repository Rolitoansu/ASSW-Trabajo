[waf]
${waf_fip} ansible_user=${ssh_user}

[frontend]
${ip_front} ansible_user=${ssh_user} ansible_ssh_common_args='-o ProxyJump=${ssh_user}@${waf_fip} -o StrictHostKeyChecking=no'

[proxy_interno]
${ip_proxy1} ansible_user=${ssh_user} ansible_ssh_common_args='-o ProxyJump=${ssh_user}@${waf_fip} -o StrictHostKeyChecking=no'
${ip_proxy2} ansible_user=${ssh_user} ansible_ssh_common_args='-o ProxyJump=${ssh_user}@${waf_fip} -o StrictHostKeyChecking=no'

[backend]
${ip_back} ansible_user=${ssh_user} ansible_ssh_common_args='-o ProxyJump=${ssh_user}@${waf_fip} -o StrictHostKeyChecking=no'

[all:vars]
backend_port=8080
