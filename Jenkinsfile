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
        // APP_VERSION akan di-set dinamis
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        // timestamps() dihapus — tidak diperlukan di pipeline modern
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: "${env.GIT_REPO}"]]
                ])
            }
        }

        stage('Read Version from package.json') {
            steps {
                script {
                    // Gunakan Node.js bawaan image Docker
                    env.APP_VERSION = sh(
                        script: 'node -p "require(\'./package.json\').version"',
                        returnStdout: true
                    ).trim()
                    echo "📦 Detected app version: ${env.APP_VERSION}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'yarn install --frozen-lockfile'
            }
        }

        stage('Lint') {
            steps {
                sh 'yarn lint || echo "⚠️ Linting skipped or failed (non-blocking)"'
            }
        }

        stage('Build Next.js') {
            steps {
                sh 'yarn build'
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

        stage('Push to Docker Registry') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh """
                        docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                        docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:latest
                        docker push ${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:v${env.APP_VERSION}
                    """
                    echo "✅ Pushed images to ${env.DOCKER_REGISTRY}"
                }
            }
        }

        stage('Create Git Tag') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Konfigurasi Git
                    sh '''
                        git config --global user.email "brillianandrie@gmail.com"
                        git config --global user.name "jagoankode"
                    '''

                    // Buat dan push tag
                    sh """
                        git tag -a v${env.APP_VERSION} -m "Release v${env.APP_VERSION} (Build #${env.BUILD_NUMBER})"
                        git push origin v${env.APP_VERSION}
                    """
                    echo "🔖 Created and pushed tag: v${env.APP_VERSION}"
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🧹 Cleaning up Docker images..."
                sh 'docker image prune -f --filter "until=1h" || true'
            }
        }

        success {
            echo "✅ Pipeline completed successfully!"
        }

        failure {
            echo "❌ Pipeline failed!"
        }
    }
}