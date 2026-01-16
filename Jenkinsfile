pipeline {
    agent any

    environment {
        // Environment variables
        GIT_REPO = 'git@github.com:jagoankode/next_jenkins.git'
        DOCKER_REGISTRY = 'localhost:8002'
        DOCKER_IMAGE_NAME = 'jenkins-next-app'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        NODE_ENV = 'production'
        APP_VERSION = readJSON(file: 'package.json').version
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "=== Checkout Source Code from ${GIT_REPO} ==="
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        userRemoteConfigs: [[url: "${GIT_REPO}"]]
                    ])
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    echo "=== Installing Dependencies ==="
                    sh '''
                        node --version
                        yarn --version
                        yarn install --frozen-lockfile
                    '''
                }
            }
        }

        stage('Lint') {
            steps {
                script {
                    echo "=== Running ESLint ==="
                    sh 'yarn lint || true'
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    echo "=== Building Next.js Application ==="
                    sh 'yarn build'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "=== Building Docker Image ==="
                    sh '''
                        docker build -t ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                        docker tag ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest
                        docker tag ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:v${APP_VERSION}
                    '''
                }
            }
        }

        stage('Push to Registry') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "=== Pushing Docker Image to Registry ==="
                    sh '''
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest
                        docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:v${APP_VERSION}
                        echo "✓ Images pushed to ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}"
                    '''
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "=== Deploying Application ==="
                    sh '''
                        # Uncomment dan sesuaikan dengan deployment method Anda
                        # Option 1: Docker Compose
                        # docker-compose -f docker-compose.yml up -d

                        # Option 2: Kubernetes
                        # kubectl set image deployment/next-app next-app=${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}

                        # Option 3: SSH Deploy
                        # ssh user@server 'cd /app && docker pull ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} && docker-compose up -d'

                        echo "Deployment configuration needed"
                    '''
                }
            }
        }

        stage('Create Git Tag') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "=== Creating Git Tag v${APP_VERSION} ==="
                    sh '''
                        git config user.email "jenkins@example.com"
                        git config user.name "Jenkins CI"
                        git tag -a v${APP_VERSION} -m "Release version ${APP_VERSION}"
                        git push origin v${APP_VERSION}
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                echo "=== Pipeline Finished ==="
                // Cleanup
                sh 'docker image prune -f --filter "until=72h" || true'
            }
        }

        success {
            echo "✓ Pipeline completed successfully"
            // Bisa tambahkan notifikasi email atau Slack di sini
        }

        failure {
            echo "✗ Pipeline failed"
            // Bisa tambahkan notifikasi email atau Slack di sini
        }

        unstable {
            echo "⚠ Pipeline unstable"
        }
    }
}
