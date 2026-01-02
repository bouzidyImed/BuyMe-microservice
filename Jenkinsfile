pipeline {
    agent any

    environment {
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'dev', 
                    url: 'git@github.com:bouzidyImed/BuyMe-microservice.git'
            }
        }

        stage('Build Java Services') {
            steps {
                script {
                    def services = [
                        'api-gateway', 'auth-register-service', 'catalogue-service',
                        'eureka-server', 'order-service', 'cart-service',
                        'kafka-service', 'payment-service'
                    ]
                    for (service in services) {
                        dir(service) {
                            sh './mvnw -B -DskipTests clean package'
                        }
                    }
                }
            }
        }

        stage('Build & Start Full Stack') {
            steps {
                script {
                    echo 'Building all Docker images (Angular runs ng serve inside container)...'
                    def buildRc = sh(script: "docker-compose -f ${DOCKER_COMPOSE_FILE} build --parallel", returnStatus: true)
                    if (buildRc != 0) {
                        sh "docker-compose -f ${DOCKER_COMPOSE_FILE} logs frontend"
                        error('Docker build failed — check frontend logs above')
                    }

                    echo 'Starting all services...'
                    sh "docker-compose -f ${DOCKER_COMPOSE_FILE} up -d"

                    // Wait for services to boot
                    sleep time: 90, unit: 'SECONDS'
                }
            }
        }

        stage('Smoke Tests') {
            steps {
                script {
                    echo 'Checking Eureka...'
                    sh 'curl -f http://localhost:8761 || exit 1'

                    echo 'Checking API Gateway...'
                    sh 'curl -f http://localhost:8081/actuator/health || exit 1'

                    echo 'Checking Angular Frontend...'
                    sh 'curl -f http://localhost:4200 || exit 1'

                    echo 'All services are healthy!'
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh "docker-compose -f ${DOCKER_COMPOSE_FILE} down --remove-orphans --volumes || true"
        }
        success {
            echo 'Pipeline passed successfully!'
        }
        failure {
            echo 'Pipeline failed — dumping logs'
            sh "docker-compose -f ${DOCKER_COMPOSE_FILE} logs --tail=500 || true"
        }
    }
}