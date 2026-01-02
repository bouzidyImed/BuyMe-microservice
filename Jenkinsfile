pipeline {
    agent any

    environment {
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'dev', url: 'git@github.com:bouzidyImed/BuyMe-microservice.git'
            }
        }
        stage('Build Java Services') {
            steps {
                script {
                    def services = [
                        'api-gateway', 'auth-register-service', 'catalogue-service',
                        'eureka-server', 'order-service', 'cart-service', 'kafka-service', 'payment-service'
                    ]
                    for (s in services) {
                        echo "Building ${s}..."
                        def rc = sh(script: "mvn -B -DskipTests -f ${s}/pom.xml clean package", returnStatus: true)
                        if (rc != 0) {
                            echo "Build failed for ${s} (rc=${rc}). See ${s}/target for logs."
                            error("Maven build failed for ${s}")
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    def rc = sh(script: "docker-compose -f ${DOCKER_COMPOSE_FILE} build --parallel", returnStatus: true)
                    if (rc != 0) {
                        echo 'docker-compose build failed; dumping compose logs for debugging'
                        sh "docker-compose -f ${DOCKER_COMPOSE_FILE} logs --no-color --tail=200 || true"
                        error('docker-compose build failed')
                    }
                }
            }
        }

        stage('Bring up Integration Environment') {
            steps {
                script {
                    def rc = sh(script: "docker-compose -f ${DOCKER_COMPOSE_FILE} up -d", returnStatus: true)
                    if (rc != 0) {
                        echo 'docker-compose up failed; dumping compose logs for debugging'
                        sh "docker-compose -f ${DOCKER_COMPOSE_FILE} logs --no-color --tail=200 || true"
                        error('docker-compose up failed')
                    }
                }
            }
        }

        stage('Build Angular Front') {
            steps {
                script {
                    def rc = sh(script: "cd BuyMe-microservice-front && npm ci && npm run build", returnStatus: true)
                    if (rc != 0) {
                        echo 'Angular build failed; printing npm logs'
                        sh "cd BuyMe-microservice-front && cat npm-debug.log || true"
                        error('Angular build failed')
                    }
                }
            }
        }

        stage('Smoke Tests') {
            steps {
                script {
                    def eureka = sh(script: "curl -sSf http://localhost:8761/ || true", returnStatus: true)
                    def gateway = sh(script: "curl -sSf http://localhost:8081/actuator/health || true", returnStatus: true)
                    if (eureka != 0 || gateway != 0) {
                        echo 'Smoke tests failed; dumping docker-compose logs for failing services'
                        sh "docker-compose -f ${DOCKER_COMPOSE_FILE} logs eureka-server api-gateway --no-color --tail=200 || true"
                        error('Smoke tests failed')
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker-compose -f ${DOCKER_COMPOSE_FILE} down --remove-orphans || true"
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}
