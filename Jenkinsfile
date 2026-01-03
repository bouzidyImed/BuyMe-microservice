pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKER_COMPOSE_FILE = 'docker-compose.yml'
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }

    stages {

        /* =======================================================
         * 1. CHECKOUT
         * ======================================================= */
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/dev']],
                    userRemoteConfigs: [[
                        url: 'git@github.com:bouzidyImed/BuyMe-microservice.git'
                    ]]
                ])
            }
        }

        /* =======================================================
         * 2. BUILD JAVA MICROSERVICES
         * ======================================================= */
        stage('Build Java Services') {
            steps {
                script {
                    def javaServices = [
                        'api-gateway',
                        'auth-register-service',
                        'catalogue-service',
                        'eureka-server',
                        'order-service',
                        'cart-service',
                        'kafka-service',
                        'payment-service'
                    ]

                    for (svc in javaServices) {
                        dir(svc) {
                            echo "▶ Building ${svc}"
                            sh '''
                                chmod +x mvnw
                                ./mvnw -B -DskipTests clean package
                            '''
                        }
                    }
                }
            }
        }

        /* =======================================================
         * 3. VALIDATE AI SERVICES
         * ======================================================= */
        stage('Validate AI Services') {
            steps {
                script {
                    def aiServices = [
                        'recommender-service',
                        'customer-segmentation-service'
                    ]

                    for (ai in aiServices) {
                        if (fileExists(ai)) {
                            dir(ai) {
                                echo "✔ AI service detected: ${ai}"
                                if (!fileExists('Dockerfile')) {
                                    error("❌ ${ai} is missing Dockerfile")
                                }
                            }
                        } else {
                            echo "⚠ AI service ${ai} not found (skipped)"
                        }
                    }
                }
            }
        }

        /* =======================================================
         * 4. BUILD DOCKER IMAGES
         * ======================================================= */
        stage('Docker Build') {
            steps {
                echo '▶ Building Docker images...'
                sh '''
                    docker-compose -f ${DOCKER_COMPOSE_FILE} build --parallel
                '''
            }
        }

        /* =======================================================
         * 5. START STACK
         * ======================================================= */
        stage('Start Stack') {
            steps {
                echo '▶ Starting all services...'
                sh '''
                    docker-compose -f ${DOCKER_COMPOSE_FILE} up -d
                '''
            }
        }

        /* =======================================================
         * 6. WAIT FOR CORE SERVICES
         * ======================================================= */
        stage('Wait for Services') {
            steps {
                echo '▶ Waiting for infrastructure to be ready...'
                sh '''
                                        wait_for() {
                                            name=$1
                                            url=$2
                                            for i in $(seq 1 30); do
                                                if curl -sf "$url" > /dev/null; then
                                                    echo "✔ $name is UP"
                                                    return 0
                                                fi
                                                echo "⏳ Waiting for $name..."
                                                sleep 10
                                            done
                                            echo "❌ $name failed to start"
                                            exit 1
                                        }

                    wait_for "Eureka" "http://localhost:8761"
                    wait_for "API Gateway" "http://localhost:8081/actuator/health"
                    wait_for "Angular Frontend" "http://localhost:4200"
                '''
            }
        }

        /* =======================================================
         * 7. SMOKE TESTS
         * ======================================================= */
        stage('Smoke Tests') {
            steps {
                echo '▶ Running smoke tests...'
                sh '''
                    curl -sf http://localhost:8761
                    curl -sf http://localhost:8081/actuator/health
                    curl -sf http://localhost:4200
                '''
                echo '✔ Smoke tests passed'
            }
        }
    }

    /* =======================================================
     * POST ACTIONS
     * ======================================================= */
    post {

        failure {
            echo '❌ Pipeline failed — dumping logs'
            sh '''
                docker-compose -f ${DOCKER_COMPOSE_FILE} ps || true
                docker-compose -f ${DOCKER_COMPOSE_FILE} logs --tail=300 || true
            '''
        }

        always {
            echo '🧹 Cleaning up Docker resources'
            sh '''
                docker-compose -f ${DOCKER_COMPOSE_FILE} down \
                  --remove-orphans \
                  --volumes || true
            '''
        }

        success {
            echo '✅ Pipeline completed successfully'
        }
    }
}
