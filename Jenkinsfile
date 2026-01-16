pipeline {
    agent any

    tools {
        nodejs 'node18'
    }

    environment {
        GIT_REPO = 'git@github.com:jagoankode/next_jenkins.git'
        GIT_CREDENTIALS = 'github-ssh'

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
                    userRemoteConfigs: [[
                        url: env.GIT_REPO,
                        credentialsId: env.GIT_CREDENTIALS
                    ]]
                ])
            }
        }

        stage('Check Environment') {
            steps {
                sh '''
                  echo "=== NODE ==="
                  node -v
                  npm -v

                  echo "=== DOCKER ==="
                  which docker || echo "docker not found"
                  docker ps || true
                '''
            }
        }

        stage('Read Version') {
            steps {
                script {
                    env.APP_VERSION = sh(
                        script: 'node -p "require(\'./package.json\').version"',
                        returnStdout: true
                    ).trim()
                    echo "📦 App version: ${env.APP_VERSION}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci || yarn install --frozen-lockfile'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint || yarn lint || echo "⚠️ Lint skipped"'
            }
        }

        stage('Build Next.js') {
            steps {
                sh 'npm run build || yarn build'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def fullImage = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    def latestImage = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:latest"
                    def versionedImage = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:v${env.APP_VERSION}"

                    sh """
                        docker build -t ${fullImage} .
                        docker tag ${fullImage} ${latestImage}
                        docker tag ${fullImage} ${versionedImage}
                    """
                }
            }
        }

        stage('Push Docker Image') {
            when { branch 'main' }
            steps {
                sh """
                    docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                    docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:latest
                    docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:v${env.APP_VERSION}
                """
            }
        }

        stage('Create Git Tag') {
            when { branch 'main' }
            steps {
                sh '''
                    git config --global user.email "brillianandrie@gmail.com"
                    git config --global user.name "jagoankode"
                '''

                sh """
                    git tag -a v${APP_VERSION} -m "Release v${APP_VERSION} (Build #${BUILD_NUMBER})"
                    git push origin v${APP_VERSION}
                """
            }
        }

        stage('Docker Cleanup') {
            steps {
                sh 'docker image prune -f --filter "until=2h" || true'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline SUCCESS"
        }
        failure {
            echo "❌ Pipeline FAILED"
        }
        always {
            echo "🏁 Pipeline finished"
        }
    }
}
