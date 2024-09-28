#### 1. Adım localde fastapi çalıştır ve kontrol et.

#### 2. Localde imaj ve container çalıştır ve uygulamayı kontrol et

```
pipeline {
    agent any

    triggers {
        githubPush()  // GitHub'dan gelen push'ları dinler
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KuserOguzHan/githup_jenkins_1.git'
            }
        }

        stage('Virtualenv and Requirements') {
            steps {
                script {
                    echo 'Setting up Python virtual environment and installing requirements...'
                    sh '''#!/bin/bash
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                    '''
                }
                echo 'Python environment is set up and requirements are installed'
            }
        }

        stage('Run FastAPI Application') {
            steps {
                script {
                    echo 'Starting FastAPI application with Uvicorn...'
                    sh '''#!/bin/bash
                    . venv/bin/activate
                    uvicorn main:app --host 0.0.0.0 --port 8002
                    '''
                }
                echo 'Uvicorn is running'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```
### 3. Docker Ortamına bağlanma İmage oluşturma ve Gönderme

- Dockerhub da token oluştur.

```
pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DOCKER_IMAGE = 'hanoguz00/fastapi-app'
        DOCKER_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KuserOguzHan/pipeline_test_production_1.git'
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
    }

    post {
        always {
            cleanWs()
        }
    }
}


```
#### 4.1. Kubectl deployment

- Service ve deployment yaml adında dosya oluştur.

```
pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DOCKER_IMAGE = 'hanoguz00/fastapi-app'
        DOCKER_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KuserOguzHan/pipeline_test_production_1.git'
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
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo 'Deploying to Kubernetes...'
                    // Kubeconfig dosyasını kullanarak kubectl ile bağlantı kur
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f deployment.yaml'
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f service.yaml'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

- Bu komut localde ubuntuda çalıştır.

```
minikube service fastapi-app-service
```

#### 4.2. Minikube komutu jenkins ile jenkinsfile da çalıştırmak.

```
pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DOCKER_IMAGE = 'hanoguz00/fastapi-app'
        DOCKER_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KuserOguzHan/pipeline_test_production_1.git'
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
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo 'Deploying to Kubernetes...'
                    // Kubeconfig dosyasını kullanarak kubectl ile bağlantı kur
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f deployment.yaml'
                    sh 'kubectl --kubeconfig=$KUBE_CONFIG apply -f service.yaml'
                }
            }
        }

        stage('Check Service Status') {
            steps {
                script {
                    echo 'Checking Kubernetes service status...'
                    sh 'kubectl get services'
                }
            }
        }

        stage('Minikube Service Access (Optional)') {
            when {
                expression {
                    return sh(script: 'minikube status', returnStatus: true) == 0
                }
            }
            steps {
                script {
                    echo 'Accessing the service using Minikube...'
                    sh 'minikube service fastapi-app-service'
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }

```

5. Test ve prod ortamında sırasıyla uygulamayı deploy etmek.

- Test ve prod için deployment ve service adında ikişer tane yaml dosyası oluştur.

```
pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DOCKER_IMAGE = 'hanoguz00/fastapi-app'
        DOCKER_TAG = 'latest'
        TEST_DEPLOYMENT_FILE = 'test-deployment.yaml'
        TEST_SERVICE_FILE = 'test-service.yaml'
        PROD_DEPLOYMENT_FILE = 'prod-deployment.yaml'
        PROD_SERVICE_FILE = 'prod-service.yaml'
        TEST_NAMESPACE = 'test'
        PROD_NAMESPACE = 'prod'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KuserOguzHan/pipeline_test_production_1.git'
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