pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        GIT_REPO = 'git@github.com:jagoankode/next_jenkins.git'
        DOCKER_REGISTRY = 'localhost:8002'
        DOCKER_IMAGE_NAME = 'jenkins-next-app'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        NODE_ENV = 'production'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    userRemoteConfigs: [[
                        url: env.GIT_REPO,
                        credentialsId: 'jenkins_jagoankode'
                    ]]
                ])
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Build Next.js') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    def fullImage = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    sh "docker build -t ${fullImage} ."
                    
                    // Hanya push jika di branch main
                    if (env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main') {
                        sh "docker push ${fullImage}"
                        echo "✅ Pushed image: ${fullImage}"
                    } else {
                        echo "ℹ️ Skipping push (not on main branch)"
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker image prune -f --filter "until=1h" || true'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}