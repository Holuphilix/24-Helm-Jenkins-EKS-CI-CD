pipeline {
    agent any

    environment {
        AWS_REGION       = 'us-east-1'
        IMAGE_NAME       = 'holuphilix/my-webapp:latest'
        HELM_BIN         = '/usr/local/bin/helm'
        KUBECONFIG       = '/home/ec2-user/.kube/config'
        EKS_CLUSTER_NAME = 'helm-eks-cluster'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Holuphilix/helm-jenkins-eks-cicd.git', branch: 'main'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔧 Building Docker image..."
                        docker build -t $IMAGE_NAME .

                        echo "🔐 Logging into Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                        echo "📤 Pushing Docker image..."
                        docker push $IMAGE_NAME

                        echo "🧹 Cleaning up local Docker image..."
                        docker rmi $IMAGE_NAME || true
                    '''
                }
            }
        }

        stage('Deploy to EKS with Helm') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-cred',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        echo "⚙️ Configuring AWS CLI..."
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        echo "📡 Updating kubeconfig for EKS cluster..."
                        aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME --kubeconfig $KUBECONFIG

                        echo "🚀 Deploying to EKS with Helm..."
                        $HELM_BIN upgrade --install my-webapp ./webapp --namespace default
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment succeeded!'
        }
        failure {
            echo '❌ Deployment failed. Please check logs above.'
        }
    }
}
