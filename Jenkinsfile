pipeline {
  agent any

  environment {
    ANSIBLE_HOST_KEY_CHECKING = 'False'
    ANSIBLE_STDOUT_CALLBACK = 'yaml'
    PATH = "/usr/local/sbin:/usr/bin/terraform:${env.PATH}"
    TF_IN_AUTOMATION = "true"
    ARM_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
    ARM_CLIENT_ID       = credentials('AZURE_CLIENT_ID')
    ARM_CLIENT_SECRET   = credentials('AZURE_CLIENT_SECRET')
    ARM_TENANT_ID       = credentials('AZURE_TENANT_ID')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        dir('terraform') {
          sh 'terraform init'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        dir('terraform') {
          sh '''
            terraform apply -auto-approve \
              -var "subscription_id=$ARM_SUBSCRIPTION_ID" \
              -var "client_id=$ARM_CLIENT_ID" \
              -var "client_secret=$ARM_CLIENT_SECRET" \
              -var "tenant_id=$ARM_TENANT_ID"
          '''
        }
      }
    }

    stage('Ansible Deploy') {
      steps {
        dir('ansible') {
          withCredentials([sshUserPrivateKey(credentialsId: 'azure-ssh-key', keyFileVariable: 'SSH_KEY')]) {
            withEnv(["ANSIBLE_HOST_KEY_CHECKING=False", "ANSIBLE_PRIVATE_KEY_FILE=$SSH_KEY"]) {
              sh 'ansible-playbook -i inventory install_web.yml'
            }
          }
        }
      }
    }

    stage('Verify') {
      steps {
        sh 'curl http://172.191.106.220'
      }
    }
  }
}

