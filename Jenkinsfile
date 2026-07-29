pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
        IMAGE_NAME = 'turbobee/fastapi-realworld-example-app'
    }

    stages {

        stage('Test') {
            steps {
                sh "docker compose -f docker-compose.test.yml -p ci-${env.BUILD_NUMBER} up --build --abort-on-container-exit --exit-code-from test"
            }
            post {
                always {
                    sh "docker compose -f docker-compose.test.yml -p ci-${env.BUILD_NUMBER} down -v --rmi local"
                }
            }
        }

        stage('Build & Push production image') {
            steps {
                script {
                    def shortSha = env.GIT_COMMIT.take(7)
                    def safeBranch = env.BRANCH_NAME.replaceAll('/', '-')
                    def tag = "${safeBranch}-${shortSha}"
                    def img = docker.build("${IMAGE_NAME}:${tag}")

                    docker.withRegistry('https://registry.hub.docker.com', DOCKERHUB_CREDENTIALS) {
                        img.push()
                        if (env.BRANCH_NAME == 'master') {
                            img.push('latest')
                        }
                    }
                }
            }
        }
    }
}
