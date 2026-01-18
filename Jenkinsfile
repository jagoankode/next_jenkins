pipeline {
    agent any

    environment {
        GIT_REPO = 'git@github.com:jagoankode/next_jenkins.git'
        DOCKER_REGISTRY = 'localhost:8002'
        DOCKER_IMAGE_NAME = 'jenkins-next-app'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        NODE_ENV = 'production'
        GIT_TAG = '' // akan diisi nanti
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
                sh 'yarn install'
                sh 'yarn --version'
            }
        }

        stage('Build Next.js') {
            steps {
                sh 'yarn build'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    def fullImage = "${env.DOCKER_REGISTRY}/${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}"
                    sh "docker build -t ${fullImage} ."
                    
                    if (env.GIT_BRANCH == 'origin/main' || env.BRANCH_NAME == 'main') {
                        sh "docker push ${fullImage}"
                        echo "✅ Pushed image: ${fullImage}"
                    } else {
                        echo "ℹ️ Skipping push (not on main branch)"
                    }
                }
            }
        }
        
        stage('Debug Branch') {
            steps {
                script {
                    echo "GIT_BRANCH = ${env.GIT_BRANCH}"
                    echo "BRANCH_NAME = ${env.BRANCH_NAME}"
                    def currentBranch = env.BRANCH_NAME ?: env.GIT_BRANCH?.replace('origin/', '')
                    echo "Normalized branch = ${currentBranch}"
                }
            }
        }
        
        stage('Prepare & Push Git Tag') {
            when {
                expression {
                    def branch = env.BRANCH_NAME ?: (env.GIT_BRANCH?.replace('origin/', '') ?: '')
                    return branch == 'main' && currentBuild.resultIsBetterOrEqualTo('SUCCESS')
                }
            }
            steps {
                script {
                    def pkg = readJSON file: 'package.json'
                    def tag = "v${pkg.version}"
                    
                    if (!tag || tag == 'vundefined') {
                        error("❌ Invalid version in package.json")
                    }

                    echo "🔖 Creating Git tag: ${tag}"
                    
                    sh """
                        git config user.email "brillianandrie@gmail.com"
                        git config user.name "jagoankode"
                        git tag -a ${tag} -m "Release ${tag}"
                        git push origin ${tag}
                    """
                    
                    echo "✅ Successfully pushed tag: ${tag}"
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
