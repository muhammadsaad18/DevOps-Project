[webservers]
${public_ip} ansible_user=${username} ansible_ssh_private_key_file=/var/jenkins_home/.ssh/id_rsa ansible_ssh_common_args='-o StrictHostKeyChecking=no'
