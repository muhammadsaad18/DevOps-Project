pipeline {
  agent any

  environment {
    ANSIBLE_HOST_KEY_CHECKING = 'False'
    ANSIBLE_STDOUT_CALLBACK = 'yaml'
    TF_IN_AUTOMATION = "true"
    ARM_SUBSCRIPTION_ID = credentials('bfbe3041-7fa8-4038-8890-37ee17f2c645')
    ARM_CLIENT_ID       = credentials('7f6ef595-1c14-46f8-959a-e44c615fb51a')
    ARM_CLIENT_SECRET   = credentials('3qM8Q~4m6iJwbf4.dPdEQkXKUCdLkDVAS_8.4ceM')
    ARM_TENANT_ID       = credentials('8651d5d5-6c2b-4448-9ac0-fede2bbc9446')
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

