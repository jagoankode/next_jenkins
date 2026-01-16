pipeline {
    agent none

    environment {
        GIT_REPO = 'git@github.com:jagoankode/next_jenkins.git'
        DOCKER_REGISTRY = 'localhost:8002'
        DOCKER_IMAGE_NAME = 'jenkins-next-app'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout') {
            agent any
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: env.GIT_REPO,
                        credentialsId: 'jenkins_jagoankode'
                    ]]
                ])
            }
        }

        stage('Install & Build (Node 18 Docker)') {
            agent {
                docker {
                    image 'node:18-alpine'
                    args '-u root:root'
                }
            }
            steps {
                sh 'node -v'
                sh 'npm -v'

                sh 'npm ci'
                sh 'npm run build'
            }
        }

        stage('Build Docker Image') {
            agent any
            steps {
                script {
                    def fullImage = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    sh "docker build -t ${fullImage} ."
                }
            }
        }

        stage('Push Docker Image') {
            agent any
            when {
                branch 'main'
            }
            steps {
                sh "docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline success"
        }
        failure {
            echo "❌ Pipeline failed"
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
