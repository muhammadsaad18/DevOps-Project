# One-Click Jenkins Pipeline Deployment

A fully automated DevOps pipeline using Jenkins (in Docker) that provisions Azure VMs with Terraform, configures them with Ansible, and deploys a static web application.

## 🚀 Features

- **One-Click Deployment**: Single Jenkins pipeline executes the entire workflow
- **Infrastructure as Code**: Terraform provisions Azure VMs with proper networking
- **Configuration Management**: Ansible installs and configures Apache web server
- **Containerized CI/CD**: Jenkins runs in Docker with all required tools
- **Automated Testing**: Pipeline includes deployment verification
- **Clean Teardown**: Option to destroy infrastructure when done

## 🛠 Technology Stack

| Tool          | Purpose                                             |
| ------------- | --------------------------------------------------- |
| **Docker**    | Host Jenkins in a container                         |
| **Jenkins**   | Automate the workflow                               |
| **Terraform** | Provision the virtual machine                       |
| **Ansible**   | Configure the VM and deploy the web app             |
| **Azure**     | Host the virtual machine                            |
| **Git**       | Store code, playbooks, and Terraform configurations |

## 📁 Project Structure

```
project/
├── terraform/
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Variable definitions
│   ├── inventory.tpl           # Ansible inventory template
│   └── terraform.tfvars.example # Example variables file
├── ansible/
│   ├── install_web.yml         # Main playbook
│   ├── ansible.cfg             # Ansible configuration
│   └── templates/
│       └── vhost.conf.j2       # Apache virtual host template
├── app/
│   └── index.html              # Static web application
├── Jenkinsfile                 # Jenkins pipeline definition
├── Dockerfile.jenkins          # Custom Jenkins image
├── plugins.txt                 # Jenkins plugins list
├── setup-jenkins.sh            # Linux/Mac setup script
├── setup-jenkins.ps1           # Windows PowerShell setup script
└── README.md                   # This file
```

## 🔧 Prerequisites

### Required Software (Windows)

- **Docker Desktop for Windows** - Download from [docker.com](https://www.docker.com/products/docker-desktop)
- **Git for Windows** - Download from [git-scm.com](https://git-scm.com/download/win)
- **PowerShell** (included with Windows)

> **Note**: All tools (Terraform, Ansible, Azure CLI) are pre-installed in the Docker container - no manual installation needed!

### Azure Requirements

- **Azure Subscription** with sufficient permissions
- **Azure Service Principal** with Contributor role
- **SSH Key Pair** for VM access

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd DevOps_Project
```

### 2. Setup Azure Service Principal

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "jenkins-devops-pipeline" --role="Contributor" --scopes="/subscriptions/<your-subscription-id>"
```

Save the output values - you'll need them for Jenkins credentials.

### 3. Run Jenkins Setup

**For Linux/Mac:**

```bash
chmod +x setup-jenkins.sh
./setup-jenkins.sh
```

**For Windows:**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup-jenkins.ps1
```

### 4. Configure Jenkins

1. Open http://localhost:8080
2. Use the initial admin password from the setup script output
3. Install suggested plugins
4. Create an admin user
5. Configure credentials (see [Credentials Setup](#credentials-setup))

### 5. Create Pipeline Job

1. Click "New Item" → "Pipeline"
2. Name it "DevOps-Pipeline"
3. Under "Pipeline" section:
   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: Your repository URL
   - Script Path: `Jenkinsfile`
4. Save and run!

## 🔐 Credentials Setup

Configure these credentials in Jenkins (Manage Jenkins → Credentials):

| Credential ID           | Type                          | Description                                                        |
| ----------------------- | ----------------------------- | ------------------------------------------------------------------ |
| `azure-client-id`       | Secret text                   | Azure Service Principal App ID                                     |
| `azure-client-secret`   | Secret text                   | Azure Service Principal Password                                   |
| `azure-subscription-id` | Secret text                   | Your Azure Subscription ID                                         |
| `azure-tenant-id`       | Secret text                   | Your Azure Tenant ID                                               |
| `ssh-private-key`       | SSH Username with private key | Username: `azureuser`, Private Key: content of `./ssh-keys/id_rsa` |

## 📝 Configuration Files

### Terraform Variables

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and update:

```hcl
resource_group_name = "your-resource-group"
location           = "East US"
prefix             = "your-prefix"
ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"
```

## 🎯 Pipeline Stages

1. **Checkout**: Clone the repository
2. **Setup SSH Key**: Configure SSH access for Ansible
3. **Terraform Init**: Initialize Terraform workspace
4. **Terraform Plan**: Plan infrastructure changes
5. **Terraform Apply/Destroy**: Apply or destroy infrastructure
6. **Wait for VM**: Wait for VM to be ready and SSH accessible
7. **Configure with Ansible**: Install Apache and deploy application
8. **Verify Deployment**: Test web application accessibility

## 🌐 Accessing Your Application

After successful deployment, your web application will be available at:

```
http://<azure-vm-public-ip>
```

The pipeline output will display the exact URL.

## 🧹 Cleanup

To destroy the infrastructure:

1. Run the pipeline again
2. Set the `ACTION` parameter to `destroy`
3. Confirm the destruction

Or manually:

```bash
cd terraform
terraform destroy
```

## 🔧 Troubleshooting

### Common Issues

**Jenkins won't start:**

- Ensure Docker is running
- Check port 8080 is not in use
- Verify Docker has sufficient resources

**Terraform authentication fails:**

- Verify Azure credentials in Jenkins
- Check service principal permissions
- Ensure subscription ID is correct

**Ansible connection fails:**

- Verify SSH key is properly configured
- Check Azure Network Security Group rules
- Ensure VM is fully booted

**Web application not accessible:**

- Check Azure NSG allows HTTP traffic (port 80)
- Verify Apache is running on the VM
- Check VM's public IP address

### Logs and Debugging

**Jenkins logs:**

```bash
docker logs jenkins
```

**Terraform debug:**

```bash
export TF_LOG=DEBUG
terraform apply
```

**Ansible verbose:**

```bash
ansible-playbook -vvv install_web.yml
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section
2. Review Jenkins and container logs
3. Open an issue in the repository

---

**Happy DevOps! 🚀**
