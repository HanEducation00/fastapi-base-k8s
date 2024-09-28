#### 1. Jenkinsfile

```
pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DOCKER_IMAGE = 'hanoguz00/fastapi-app'
        DOCKER_TAG = 'latest'
        TEST_DEPLOYMENT_FILE = 'k8s.test/test-deployment.yaml'
        TEST_SERVICE_FILE = 'k8s.test/test-service.yaml'
        PROD_DEPLOYMENT_FILE = 'k8s.prod/prod-deployment.yaml'
        PROD_SERVICE_FILE = 'k8s.prod/prod-service.yaml'
        TEST_NAMESPACE = 'test'
        PROD_NAMESPACE = 'prod'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KuserOguzHan/pipeline_test_production_2.git'
            }
        }

        stage('Docker Login') {
            steps {
                script {
                    echo 'Logging into Docker Hub...'
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh 'docker build -t $DOCKER_IMAGE:$DOCKER_TAG .'
                }
            }
        }

        stage('Push Docker Image to Hub') {
            steps {
                script {
                    echo 'Pushing Docker image to Docker Hub...'
                    sh 'docker push $DOCKER_IMAGE:$DOCKER_TAG'
                }
            }
        }
        
        stage('Deploy to Test') {
            steps {
                script {
                    echo 'Deploying to Test environment in test namespace...'
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f $TEST_DEPLOYMENT_FILE -n $TEST_NAMESPACE'
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f $TEST_SERVICE_FILE -n $TEST_NAMESPACE'
                }
            }
        }

        stage('Check Test Service and Deployment Status') {
            steps {
                script {
                    echo 'Checking Test Kubernetes service and deployment status...'
                    sh 'kubectl get services -n $TEST_NAMESPACE'
                    sh 'kubectl get deployments -n $TEST_NAMESPACE'
                }
            }
        }

        stage('Deploy to Prod') {
            steps {
                script {
                    echo 'Deploying to Prod environment in prod namespace...'
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f $PROD_DEPLOYMENT_FILE -n $PROD_NAMESPACE'
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f $PROD_SERVICE_FILE -n $PROD_NAMESPACE'
                }
            }
        }

        stage('Check Prod Service Status') {
            steps {
                script {
                    echo 'Checking Prod Kubernetes service status...'
                    sh 'kubectl get services -n $PROD_NAMESPACE'
                }
            }
        }

        stage('Access Prod Service via Minikube') {
            when {
                expression {
                    return sh(script: 'minikube status', returnStatus: true) == 0
                }
            }
            steps {
                script {
                    echo 'Accessing the Prod service using Minikube...'
                    sh 'minikube service fastapi-app-prod-service -n $PROD_NAMESPACE'
                }
            }
        }
    }
}

```