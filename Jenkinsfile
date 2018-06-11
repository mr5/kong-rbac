pipeline {
    agent {
        docker {
            image 'docker'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t hhy5861/kong-rbac .'
            }
        }
    }
}