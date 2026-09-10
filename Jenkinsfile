pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '675789571925'
        AWS_REGION     = 'ap-south-1'
        AWS_CRED_ID    = 'Shashank-aws-ecr-credentials'
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
    }

    options {
        disableConcurrentBuilds()
        timeout(time: 25, unit: 'MINUTES')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "==> [1/5] Checking out source repository from GitHub"
                checkout scm
            }
        }

        stage('Authenticate with Amazon ECR') {
            steps {
                echo "==> [2/5] Logging into Amazon ECR Registry: ${ECR_REGISTRY}"
                withCredentials([usernamePassword(credentialsId: env.AWS_CRED_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    """
                }
            }
        }

        stage('Parallel Docker Build') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo "==> [3a/5] Building Frontend React + NGINX Image"
                        sh """
                            docker build \
                              --build-arg REACT_APP_AUTH_API_URL=/api/auth \
                              --build-arg REACT_APP_STREAMING_API_URL=/api/streaming \
                              --build-arg REACT_APP_STREAMING_PUBLIC_URL=/api/streaming \
                              --build-arg REACT_APP_ADMIN_API_URL=/api/admin \
                              --build-arg REACT_APP_CHAT_API_URL=/api/chat \
                              --build-arg REACT_APP_CHAT_SOCKET_URL=/ \
                              -t ${ECR_REGISTRY}/streamingapp-frontend:${IMAGE_TAG} \
                              -t ${ECR_REGISTRY}/streamingapp-frontend:latest \
                              ./frontend
                        """
                    }
                }

                stage('Build Auth Service') {
                    steps {
                        echo "==> [3b/5] Building Auth Service Image"
                        sh """
                            docker build \
                              -t ${ECR_REGISTRY}/streamingapp-auth:${IMAGE_TAG} \
                              -t ${ECR_REGISTRY}/streamingapp-auth:latest \
                              ./backend/authService
                        """
                    }
                }

                stage('Build Streaming Service') {
                    steps {
                        echo "==> [3c/5] Building Streaming Service Image"
                        sh """
                            docker build \
                              -t ${ECR_REGISTRY}/streamingapp-streaming:${IMAGE_TAG} \
                              -t ${ECR_REGISTRY}/streamingapp-streaming:latest \
                              ./backend/streamingService
                        """
                    }
                }

                stage('Build Admin Service') {
                    steps {
                        echo "==> [3d/5] Building Admin Service Image"
                        sh """
                            docker build \
                              -t ${ECR_REGISTRY}/streamingapp-admin:${IMAGE_TAG} \
                              -t ${ECR_REGISTRY}/streamingapp-admin:latest \
                              ./backend/adminService
                        """
                    }
                }

                stage('Build Chat Service') {
                    steps {
                        echo "==> [3e/5] Building Chat Service Image"
                        sh """
                            docker build \
                              -t ${ECR_REGISTRY}/streamingapp-chat:${IMAGE_TAG} \
                              -t ${ECR_REGISTRY}/streamingapp-chat:latest \
                              ./backend/chatService
                        """
                    }
                }
            }
        }

        stage('Push Images to Amazon ECR') {
            steps {
                echo "==> [4/5] Pushing all 5 multi-service images to personal Amazon ECR"
                sh """
                    # Push Frontend
                    docker push ${ECR_REGISTRY}/streamingapp-frontend:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/streamingapp-frontend:latest

                    # Push Auth Service
                    docker push ${ECR_REGISTRY}/streamingapp-auth:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/streamingapp-auth:latest

                    # Push Streaming Service
                    docker push ${ECR_REGISTRY}/streamingapp-streaming:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/streamingapp-streaming:latest

                    # Push Admin Service
                    docker push ${ECR_REGISTRY}/streamingapp-admin:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/streamingapp-admin:latest

                    # Push Chat Service
                    docker push ${ECR_REGISTRY}/streamingapp-chat:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/streamingapp-chat:latest
                """
            }
        }
    }

    post {
        always {
            echo "==> [5/5] Performing cleanup on shared Jenkins agent disk"
            sh """
                docker rmi -f ${ECR_REGISTRY}/streamingapp-frontend:${IMAGE_TAG} || true
                docker rmi -f ${ECR_REGISTRY}/streamingapp-auth:${IMAGE_TAG} || true
                docker rmi -f ${ECR_REGISTRY}/streamingapp-streaming:${IMAGE_TAG} || true
                docker rmi -f ${ECR_REGISTRY}/streamingapp-admin:${IMAGE_TAG} || true
                docker rmi -f ${ECR_REGISTRY}/streamingapp-chat:${IMAGE_TAG} || true
            """
        }
        success {
            echo "SUCCESS: All 5 images successfully built, tagged with ${IMAGE_TAG}, and published to ECR!"
        }
        failure {
            echo "FAILURE: Build or push failed. Check console output above for error logs."
        }
    }
}
