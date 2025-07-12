pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        DOCKERHUB_IMAGE = 'holuphilix/my-webapp:latest'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Build and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "Building Docker image..."
                        docker build -t $DOCKERHUB_IMAGE .

                        echo "Logging in to Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                        echo "Pushing image to Docker Hub..."
                        docker push $DOCKERHUB_IMAGE

                        echo "Cleaning up local image..."
                        docker rmi $DOCKERHUB_IMAGE || true
                    '''
                }
            }
        }

        stage('Deploy with Helm') {
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
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        echo "Configuring access to EKS..."
                        aws eks --region ${AWS_DEFAULT_REGION} update-kubeconfig --name my-eks-cluster

                        echo "Deploying to EKS with Helm..."
                        helm upgrade --install my-webapp ./webapp --namespace default
                    '''
                }
            }
        }
    }
}