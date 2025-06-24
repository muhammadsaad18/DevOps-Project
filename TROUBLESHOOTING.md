# 🔧 Troubleshooting Guide

Common issues and solutions for the DevOps pipeline.

## 🐳 Docker Issues

### Jenkins Container Won't Start

**Symptoms:**
- `docker run` command fails
- Container exits immediately

**Solutions:**
```bash
# Check if port 8080 is in use
netstat -an | grep 8080

# Check Docker daemon
docker info

# Check available resources
docker system df

# Remove existing container
docker rm -f jenkins

# Check logs
docker logs jenkins
```

### Permission Issues (Linux/Mac)

**Symptoms:**
- Permission denied errors
- Cannot access Docker socket

**Solutions:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Restart session or run
newgrp docker

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

## 🔐 Authentication Issues

### Azure Authentication Fails

**Symptoms:**
- "Error: building AzureRM Client" in Terraform
- Authentication errors in pipeline

**Solutions:**

1. **Verify Service Principal:**
```bash
az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID
```

2. **Check Permissions:**
```bash
az role assignment list --assignee CLIENT_ID
```

3. **Verify Subscription:**
```bash
az account show
```

### SSH Key Issues

**Symptoms:**
- Ansible cannot connect to VM
- "Permission denied (publickey)" errors

**Solutions:**

1. **Check SSH key format:**
```bash
ssh-keygen -l -f ./ssh-keys/id_rsa.pub
```

2. **Verify key in terraform.tfvars:**
```bash
cat terraform/terraform.tfvars | grep ssh_public_key
```

3. **Test SSH connection:**
```bash
ssh -i ./ssh-keys/id_rsa azureuser@VM_IP
```

## 🏗️ Terraform Issues

### State Lock Issues

**Symptoms:**
- "Error: Error locking state"
- State file locked

**Solutions:**
```bash
cd terraform
terraform force-unlock LOCK_ID
```

### Resource Already Exists

**Symptoms:**
- "already exists" errors during apply

**Solutions:**
```bash
# Import existing resource
terraform import azurerm_resource_group.main /subscriptions/SUB_ID/resourceGroups/RG_NAME

# Or destroy and recreate
terraform destroy
terraform apply
```

### Invalid Configuration

**Symptoms:**
- Validation errors
- Invalid resource configurations

**Solutions:**
```bash
# Validate configuration
terraform validate

# Format code
terraform fmt

# Check plan
terraform plan
```

## 🔧 Ansible Issues

### Inventory File Not Found

**Symptoms:**
- "Could not match supplied host pattern"
- Inventory file missing

**Solutions:**

1. **Check if Terraform completed:**
```bash
ls -la ansible/inventory
```

2. **Manually create inventory:**
```bash
echo "[webservers]" > ansible/inventory
echo "VM_IP ansible_user=azureuser ansible_ssh_private_key_file=/var/jenkins_home/.ssh/id_rsa" >> ansible/inventory
```

### Connection Timeout

**Symptoms:**
- SSH timeout errors
- "UNREACHABLE" host status

**Solutions:**

1. **Check VM status:**
```bash
az vm show -g RESOURCE_GROUP -n VM_NAME --query "powerState"
```

2. **Verify NSG rules:**
```bash
az network nsg rule list -g RESOURCE_GROUP --nsg-name NSG_NAME
```

3. **Test connectivity:**
```bash
telnet VM_IP 22
```

### Package Installation Fails

**Symptoms:**
- apt/yum errors
- Package not found

**Solutions:**

1. **Update package cache:**
```yaml
- name: Update package cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
```

2. **Check VM internet connectivity:**
```bash
ssh azureuser@VM_IP "ping -c 3 google.com"
```

## 🌐 Web Application Issues

### Application Not Accessible

**Symptoms:**
- HTTP timeout
- Connection refused

**Solutions:**

1. **Check Apache status:**
```bash
ssh azureuser@VM_IP "sudo systemctl status apache2"
```

2. **Verify port 80 is open:**
```bash
ssh azureuser@VM_IP "sudo netstat -tlnp | grep :80"
```

3. **Check firewall:**
```bash
ssh azureuser@VM_IP "sudo ufw status"
```

4. **Test locally on VM:**
```bash
ssh azureuser@VM_IP "curl -I http://localhost"
```

### Wrong Content Displayed

**Symptoms:**
- Default Apache page shown
- Old content displayed

**Solutions:**

1. **Check file permissions:**
```bash
ssh azureuser@VM_IP "ls -la /var/www/html/"
```

2. **Restart Apache:**
```bash
ssh azureuser@VM_IP "sudo systemctl restart apache2"
```

3. **Clear browser cache**

## 📊 Jenkins Issues

### Pipeline Fails at Specific Stage

**Symptoms:**
- Stage marked as failed
- Red X in pipeline view

**Solutions:**

1. **Check console output:**
   - Click on failed stage
   - Review logs for error messages

2. **Enable debug mode:**
```groovy
// Add to Jenkinsfile
environment {
    TF_LOG = 'DEBUG'
}
```

3. **Run commands manually:**
```bash
# SSH into Jenkins container
docker exec -it jenkins bash

# Run failed command manually
cd /workspace
terraform plan
```

### Credentials Not Found

**Symptoms:**
- "Credentials not found" errors
- Authentication failures

**Solutions:**

1. **Verify credential IDs match:**
   - Check Jenkinsfile credential IDs
   - Compare with Jenkins credential store

2. **Test credentials:**
   - Manage Jenkins → Credentials
   - Click on credential → Update
   - Test connection

### Build Hangs

**Symptoms:**
- Pipeline stuck at stage
- No progress for long time

**Solutions:**

1. **Check resource usage:**
```bash
docker stats jenkins
```

2. **Increase timeouts:**
```groovy
timeout(time: 30, unit: 'MINUTES') {
    // Your stage content
}
```

3. **Restart Jenkins:**
```bash
docker restart jenkins
```

## 🚨 Emergency Procedures

### Complete Reset

If everything is broken:

```bash
# Stop and remove Jenkins
docker stop jenkins
docker rm jenkins
docker volume rm jenkins_home

# Clean up Azure resources
cd terraform
terraform destroy -auto-approve

# Remove local files
rm -rf ssh-keys/
rm terraform/terraform.tfvars
rm ansible/inventory

# Start fresh
./setup-jenkins.sh
```

### Quick Health Check

```bash
# Check all services
docker ps | grep jenkins
curl -I http://localhost:8080
az account show
terraform version
ansible --version
```

## 📞 Getting Help

1. **Check logs first:**
   - Jenkins console output
   - Docker container logs
   - Azure activity log

2. **Search for error messages:**
   - Copy exact error text
   - Search in documentation
   - Check GitHub issues

3. **Provide context when asking for help:**
   - Operating system
   - Error messages
   - Steps to reproduce
   - Configuration files (without secrets)

---

**Remember:** Most issues are configuration-related. Double-check credentials, permissions, and network settings first! 🔍
