pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        IMAGE_NAME = 'holuphilix/my-webapp:latest'
        HELM_BIN = '/usr/local/bin/helm'
        KUBECONFIG = '/home/ec2-user/.kube/config'
    }

    triggers {
        githubPush() // Trigger the pipeline on GitHub push
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
                    credentialsId: 'docker-cred', // Docker Hub credentials
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔧 Building Docker image..."
                        docker build -t $IMAGE_NAME .

                        echo "🔐 Logging into Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                        echo "📤 Pushing image to Docker Hub..."
                        docker push $IMAGE_NAME
                    '''
                }
            }
        }

        stage('Deploy to EKS with Helm') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-cred', // AWS IAM programmatic credentials
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        echo "⚙️ Configuring AWS CLI for EKS..."
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION

                        echo "📡 Updating kubeconfig for EKS cluster..."
                        aws eks update-kubeconfig --region $AWS_REGION --name helm-eks-cluster

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
            echo '❌ Deployment failed. Check logs above.'
        }
    }
}
