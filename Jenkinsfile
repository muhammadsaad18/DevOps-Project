pipeline {
    agent any
    
    environment {
        // Azure credentials - configure these in Jenkins credentials
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_CLIENT_SECRET = credentials('azure-client-secret')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID = credentials('azure-tenant-id')
        
        // SSH key for VM access
        SSH_PRIVATE_KEY = credentials('ssh-private-key')
        
        // Terraform workspace
        TF_WORKSPACE = 'default'
        TF_IN_AUTOMATION = 'true'
    }
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Choose whether to apply or destroy infrastructure'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Auto-approve Terraform changes (use with caution)'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                
                // Display workspace contents
                sh 'ls -la'
                sh 'pwd'
            }
        }
        
        stage('Setup SSH Key') {
            steps {
                echo 'Setting up SSH key for Ansible...'
                sh '''
                    mkdir -p /var/jenkins_home/.ssh
                    echo "$SSH_PRIVATE_KEY" > /var/jenkins_home/.ssh/id_rsa
                    chmod 600 /var/jenkins_home/.ssh/id_rsa
                    ssh-keygen -y -f /var/jenkins_home/.ssh/id_rsa > /var/jenkins_home/.ssh/id_rsa.pub
                '''
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    echo 'Initializing Terraform...'
                    sh 'terraform init'
                    sh 'terraform version'
                    sh 'terraform validate'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    echo 'Planning Terraform changes...'
                    script {
                        if (params.ACTION == 'destroy') {
                            sh 'terraform plan -destroy -out=tfplan'
                        } else {
                            sh '''
                                # Create terraform.tfvars with SSH public key
                                echo "ssh_public_key = \\"$(cat /var/jenkins_home/.ssh/id_rsa.pub)\\"" > terraform.tfvars
                                terraform plan -out=tfplan
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Terraform Apply/Destroy') {
            steps {
                dir('terraform') {
                    script {
                        if (params.AUTO_APPROVE) {
                            echo "Auto-approving Terraform ${params.ACTION}..."
                            sh 'terraform apply -auto-approve tfplan'
                        } else {
                            echo "Manual approval required for Terraform ${params.ACTION}"
                            input message: "Do you want to ${params.ACTION} the infrastructure?", ok: "Yes, ${params.ACTION}!"
                            sh 'terraform apply tfplan'
                        }
                    }
                }
            }
        }
        
        stage('Wait for VM') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo 'Waiting for VM to be ready...'
                dir('terraform') {
                    script {
                        def publicIp = sh(
                            script: 'terraform output -raw public_ip_address',
                            returnStdout: true
                        ).trim()
                        
                        echo "VM Public IP: ${publicIp}"
                        
                        // Wait for SSH to be available
                        timeout(time: 10, unit: 'MINUTES') {
                            waitUntil {
                                script {
                                    def result = sh(
                                        script: "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /var/jenkins_home/.ssh/id_rsa azureuser@${publicIp} 'echo SSH_OK'",
                                        returnStatus: true
                                    )
                                    return result == 0
                                }
                            }
                        }
                        echo 'VM is ready and SSH is accessible!'
                    }
                }
            }
        }
        
        stage('Configure with Ansible') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('ansible') {
                    echo 'Configuring VM with Ansible...'
                    
                    // Check if inventory file exists
                    sh 'ls -la'
                    sh 'cat inventory || echo "Inventory file not found"'
                    
                    // Run Ansible playbook
                    sh '''
                        ansible --version
                        ansible-playbook -i inventory install_web.yml -v
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('terraform') {
                    echo 'Verifying web application deployment...'
                    script {
                        def publicIp = sh(
                            script: 'terraform output -raw public_ip_address',
                            returnStdout: true
                        ).trim()
                        
                        echo "Testing web application at: http://${publicIp}"
                        
                        // Test web server response
                        timeout(time: 5, unit: 'MINUTES') {
                            waitUntil {
                                script {
                                    def result = sh(
                                        script: "curl -f -s -o /dev/null -w '%{http_code}' http://${publicIp}",
                                        returnStdout: true
                                    ).trim()
                                    echo "HTTP Response Code: ${result}"
                                    return result == '200'
                                }
                            }
                        }
                        
                        echo "✅ Web application is successfully deployed and accessible!"
                        echo "🌐 Access your application at: http://${publicIp}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed.'
            
            // Archive Terraform plan and state files
            archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
            archiveArtifacts artifacts: 'terraform/terraform.tfstate*', allowEmptyArchive: true
            
            // Clean up sensitive files
            sh '''
                rm -f /var/jenkins_home/.ssh/id_rsa
                rm -f terraform/terraform.tfvars
            '''
        }
        
        success {
            echo '🎉 Pipeline completed successfully!'
            script {
                if (params.ACTION == 'apply') {
                    dir('terraform') {
                        def publicIp = sh(
                            script: 'terraform output -raw public_ip_address || echo "N/A"',
                            returnStdout: true
                        ).trim()
                        
                        if (publicIp != 'N/A') {
                            echo """
                            ========================================
                            🚀 DEPLOYMENT SUCCESSFUL! 🚀
                            ========================================
                            
                            Your web application is now live at:
                            🌐 http://${publicIp}
                            
                            Infrastructure Details:
                            📍 Public IP: ${publicIp}
                            ☁️  Platform: Azure
                            🔧 Web Server: Apache
                            📦 Deployed via: Jenkins Pipeline
                            
                            ========================================
                            """
                        }
                    }
                } else {
                    echo """
                    ========================================
                    🗑️  INFRASTRUCTURE DESTROYED! 🗑️
                    ========================================
                    
                    All Azure resources have been successfully removed.
                    
                    ========================================
                    """
                }
            }
        }
        
        failure {
            echo '❌ Pipeline failed! Check the logs for details.'
            
            // Attempt to show Terraform state for debugging
            dir('terraform') {
                sh 'terraform show || echo "No Terraform state available"'
            }
        }
        
        cleanup {
            echo 'Performing cleanup...'
            // Additional cleanup if needed
        }
    }
}
