# Automated DevOps CI/CD Pipeline

This project demonstrates a fully automated CI/CD pipeline using Jenkins, Terraform, Ansible, and Docker to deploy a static website on an Azure VM. It provisions infrastructure, configures a web server, and deploys the application—all in one seamless Jenkins pipeline.

## Objective
Automate the provisioning of an Azure VM, install Apache, and deploy a static website with a single Jenkins pipeline, showcasing a robust DevOps workflow.

## Technology Stack
- Docker: Containerizes Jenkins for portability
- Jenkins: Orchestrates the CI/CD pipeline
- Terraform: Provisions Azure infrastructure
- Ansible: Configures VM and deploys the app
- Azure: Hosts the Ubuntu VM
- Git: Manages source code and versioning

## Project Structure
project/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                 # Azure resource definitions
│   ├── variables.tf            # Variable declarations
│   └── terraform.tfvars.example # Example variable values
├── ansible/                      # Server configuration
│   ├── install_web.yml         # Apache installation playbook
│   └── deploy_app.yml          # App deployment playbook
├── app/                         # Static website files
│   └── index.html              # Sample webpage
├── Jenkinsfile                  # Pipeline script
└── README.txt                   # Project documentation

## Getting Started

### Prerequisites
- Active Azure subscription
- Docker installed
- SSH key pair for VM access
- Git repository with this project

### Step 1: Launch Jenkins in Docker
Run Jenkins with necessary tools mounted:
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which terraform):/usr/local/bin/terraform \
  -v $(which ansible-playbook):/usr/local/bin/ansible-playbook \
  -v $(pwd):/workspace \
  jenkins/jenkins:lts

### Step 2: Configure Jenkins
1. Access Jenkins at http://localhost:8080
2. Complete the initial setup and install suggested plugins
3. Install additional plugins:
   - Git
   - Pipeline
   - SSH Agent
4. Add credentials in Manage Jenkins → Credentials → Global:
   | ID                        | Type                          | Description                           |
   |---------------------------|-------------------------------|---------------------------------------|
   | azure-subscription-id     | Secret text                   | Azure subscription ID                 |
   | azure-client-id           | Secret text                   | Azure service principal client ID     |
   | azure-client-secret       | Secret text                   | Azure service principal secret        |
   | azure-tenant-id           | Secret text                   | Azure tenant ID                      |
   | azure-vm-ssh-key          | SSH Username with private key | Private key for VM access (e.g., azureuser) |
   | azure-vm-ssh-public-key   | Secret text                   | Public key for VM access             |

### Step 3: Configure Terraform
1. Copy terraform/terraform.tfvars.example to terraform/terraform.tfvars
2. Update with your values:
   resource_group_name = "devops-pipeline-rg"
   location           = "East US"
   prefix             = "devops"
   vm_size            = "Standard_B1s"
   admin_username     = "azureuser"
   ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"

### Step 4: Set Up Jenkins Pipeline
1. Create a new Pipeline job in Jenkins
2. Point it to your Git repository
3. Set the pipeline script path to Jenkinsfile
4. Run the pipeline

## Pipeline Stages
1. Checkout: Clones the repository
2. Terraform Init & Apply: Provisions Azure resources (Resource Group, VNet, Subnet, Public IP, NIC, Ubuntu VM)
3. Ansible Configure & Deploy: Installs Apache and deploys index.html to /var/www/html
4. Verify: Checks deployment success via curl http://<public_ip>

## Accessing the Website
After a successful run, visit:
http://<public_ip>

## Cleanup
To avoid Azure charges, destroy resources:
cd terraform
terraform destroy -auto-approve

Or use Azure CLI:
az group delete --name devops-pipeline-rg --yes --no-wait

## Troubleshooting
- SSH Timeout: Verify NSG allows port 22; check SSH key configuration
- Terraform Auth Errors: Validate Azure credentials; ensure service principal has permissions
- Ansible Connection: Confirm VM is running; check SSH key permissions and format

Debugging Tips:
- Review Jenkins build logs for detailed errors
- Enable verbose Ansible output (-v) in the pipeline
- Check Terraform state files in the workspace

## Security Best Practices
- Secrets Management: Store sensitive data in Azure Key Vault for production
- Access Control: Restrict NSG rules to allow only necessary ports (22, 80)
- Key Rotation: Regularly update SSH keys and service principal credentials
- Git Security: Exclude terraform.tfvars from version control

## Production Enhancements
- Add automated unit and integration tests
- Implement blue-green or canary deployments
- Enable monitoring with tools like Prometheus/Grafana
- Use Terraform remote state (e.g., Azure Blob Storage)
- Integrate cost monitoring for Azure resources

## Contributing
1. Fork the repository
2. Create a feature branch (git checkout -b feature/your-feature)
3. Commit changes (git commit -m "Add feature")
4. Push to the branch (git push origin feature/your-feature)
5. Open a pull request

## License
Licensed under the MIT License (see LICENSE file).

## Support
- Check Jenkins logs and Azure portal for issues
- Open an issue in the repository for assistance
- Refer to the troubleshooting section