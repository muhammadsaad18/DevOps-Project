# 🚀 Quick Start Guide

Get your DevOps pipeline running in 10 minutes!

## ⚡ Prerequisites Check

- [ ] Docker Desktop installed and running
- [ ] Azure subscription with admin access
- [ ] Git installed

## 🎯 Step-by-Step Setup

### 1. Get Azure Credentials (5 minutes)

```bash
# Login to Azure
az login

# Create service principal (replace YOUR_SUBSCRIPTION_ID)
az ad sp create-for-rbac --name "jenkins-devops" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

**Save this output!** You'll need:

- `appId` → azure-client-id
- `password` → azure-client-secret
- `tenant` → azure-tenant-id
- Your subscription ID → azure-subscription-id

### 2. Setup Jenkins (2 minutes)

**Windows:**

```powershell
.\setup-jenkins.ps1
```

**Copy the SSH public key** from the output!

### 3. Configure Jenkins (3 minutes)

1. Open http://localhost:8080
2. Enter the admin password from setup script
3. Install suggested plugins
4. Create admin user
5. Go to "Manage Jenkins" → "Credentials" → "System" → "Global credentials"
6. Add these 5 credentials:

| ID                      | Type                          | Value                                                      |
| ----------------------- | ----------------------------- | ---------------------------------------------------------- |
| `azure-client-id`       | Secret text                   | appId from step 1                                          |
| `azure-client-secret`   | Secret text                   | password from step 1                                       |
| `azure-subscription-id` | Secret text                   | Your subscription ID                                       |
| `azure-tenant-id`       | Secret text                   | tenant from step 1                                         |
| `ssh-private-key`       | SSH Username with private key | Username: `azureuser`, Key: content of `./ssh-keys/id_rsa` |

### 4. Create Terraform Config (1 minute)

```bash
# Copy example file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your values
# Add the SSH public key from step 2
```

### 5. Create Pipeline Job (2 minutes)

1. Jenkins Dashboard → "New Item"
2. Name: "DevOps-Pipeline"
3. Type: "Pipeline"
4. Pipeline section:
   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: Your repo URL
   - Script Path: `Jenkinsfile`
5. Save

### 6. Run Pipeline! (5-10 minutes)

1. Click "Build with Parameters"
2. ACTION: `apply`
3. AUTO_APPROVE: ✅ (for demo)
4. Click "Build"

## 🎉 Success!

Your web app will be live at: `http://YOUR_VM_IP`

## 🧹 Cleanup

Run pipeline again with ACTION: `destroy`

## 🆘 Need Help?

**Jenkins won't start?**

```bash
docker logs jenkins
```

**Pipeline fails?**

- Check credentials are correct
- Verify Azure permissions
- Check Jenkins console output

**Can't access web app?**

- Wait 2-3 minutes after pipeline completes
- Check Azure portal for VM status
- Verify NSG allows HTTP traffic

---

**Total time: ~10 minutes** ⏱️
