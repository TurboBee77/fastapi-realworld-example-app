pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
        IMAGE_NAME = 'turbobee/fastapi-realworld-example-app'
        INFRA_REPO = 'https://github.com/TurboBee77/fastapi-devops-infra.git'
    }

    stages {

        stage('Test') {
            options {
               timeout(time: 15, unit: 'MINUTES')
            }
            steps {
                sh "docker compose -f docker-compose.test.yml -p ci-${env.BRANCH_NAME.replaceAll('/', '-')}-${env.BUILD_NUMBER} up --build --abort-on-container-exit --exit-code-from test"
            }
            post {
                always {
                    sh "mkdir -p test-results"
                    sh "docker compose -f docker-compose.test.yml -p ci-${env.BRANCH_NAME.replaceAll('/', '-')}-${env.BUILD_NUMBER} cp test:/app/test-results/junit.xml test-results/junit.xml || true"
                    junit testResults: 'test-results/junit.xml', allowEmptyResults: true
                    sh "docker compose -f docker-compose.test.yml -p ci-${env.BRANCH_NAME.replaceAll('/', '-')}-${env.BUILD_NUMBER} down -v --rmi local"
                }
            }
        }

        stage('Build & Push production image') {
            options {
               timeout(time: 15, unit: 'MINUTES')
            }
            steps {
                script {
                    def shortSha = env.GIT_COMMIT.take(7)
                    def safeBranch = env.BRANCH_NAME.replaceAll('/', '-')
                    env.IMAGE_TAG = "${safeBranch}-${shortSha}"
                    def img = docker.build("${IMAGE_NAME}:${env.IMAGE_TAG}")

                    docker.withRegistry('https://registry.hub.docker.com', DOCKERHUB_CREDENTIALS) {
                        img.push()
                        if (env.BRANCH_NAME == 'master') {
                            img.push('latest')
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when { branch 'master' }
            options {
               timeout(time: 10, unit: 'MINUTES')
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ssh_cd_key', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')
                ]) {
                    sh '''
                        set -e

                        rm -rf infra
                        git clone --depth 1 "$INFRA_REPO" infra
                        cd infra/ansible
                        trap 'rm -f .vault_pass.txt' EXIT

                        APP_HOST=$(cat /run/secrets/app_host_ip)
                        printf '[app]\\n%s ansible_user=ubuntu\\n' "$APP_HOST" > inventory_cd.ini

                        echo "$VAULT_PASS" > .vault_pass.txt
                        chmod 600 .vault_pass.txt

                        ansible-playbook -i inventory_cd.ini site.yml --limit app \\
                            --private-key="$SSH_KEY" \\
                            --vault-password-file=.vault_pass.txt \\
                            --extra-vars "app_image_tag=$IMAGE_TAG manage_cd_key=false"
                    '''
                }
            }
        }
    }

    post {
        success {
            withCredentials([string(credentialsId: 'discord-webhook-url', variable: 'DISCORD_WEBHOOK')]) {
                sh '''
                    curl -s -H "Content-Type: application/json" \\
                        -d "{\\"content\\": \\"✅ Build #${BUILD_NUMBER} (${BRANCH_NAME}) zakonczony sukcesem: ${BUILD_URL}\\"}" \\
                        "$DISCORD_WEBHOOK"
                '''
            }
        }
        failure {
            withCredentials([string(credentialsId: 'discord-webhook-url', variable: 'DISCORD_WEBHOOK')]) {
                sh '''
                    curl -s -H "Content-Type: application/json" \\
                        -d "{\\"content\\": \\"❌ Build #${BUILD_NUMBER} (${BRANCH_NAME}) zakonczony bledem: ${BUILD_URL}\\"}" \\
                        "$DISCORD_WEBHOOK"
                '''
            }
        }
    }
}
