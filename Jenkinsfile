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
                    def javaServices = [
                        'api-gateway', 'auth-register-service', 'catalogue-service',
                        'eureka-server', 'order-service', 'cart-service',
                        'kafka-service', 'payment-service'
                    ]
                    for (svc in javaServices) {
                        dir(svc) {
                            echo "Building Java service ${svc} with Maven..."
                            sh './mvnw -B -DskipTests clean package'
                        }
                    }
                }
            }
        }

        stage('Validate AI Services') {
            steps {
                script {
                    // AI services are built via their Dockerfiles during docker-compose build.
                    // Here we check presence and basic files so builds are predictable.
                    def aiServices = ['recommender-service', 'customer-segmentation-service']
                    for (ai in aiServices) {
                        if (fileExists(ai)) {
                            dir(ai) {
                                echo "Found AI service: ${ai}"
                                if (fileExists('requirements.txt')) {
                                    echo "${ai} has requirements.txt (will be installed in image)."
                                } else {
                                    echo "${ai} has no requirements.txt. Ensure Dockerfile handles dependencies."
                                }
                            }
                        } else {
                            echo "Warning: AI service directory ${ai} not found in workspace."
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