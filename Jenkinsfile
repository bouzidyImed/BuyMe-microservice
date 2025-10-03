pipeline {
    agent any

    environment {
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'git@github.com:bouzidyImed/BuyMe-microservice.git'
            }
        }

        stage('Build Services') {
            steps {
                script {
                    // Example: build all microservices with Maven
                    sh 'cd api-gateway && mvn clean package -DskipTests'
                    sh 'cd auth-register-service && mvn clean package -DskipTests'
                    sh 'cd catalogue-service && mvn clean package -DskipTests'
                    sh 'cd eureka-server && mvn clean package -DskipTests'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    sh 'docker-compose build'
                }
            }
        }

        stage('Run Containers') {
            steps {
                script {
                    sh 'docker-compose up -d'
                }
            }
        }

        stage('Run Angular Front') {
            steps {
                script {
                    sh 'cd angular-front && npm install && npm run build'
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}
