pipeline {
  agent {
    dockerfile {
      filename 'Dockerfile'
    }

  }
  stages {
    stage('build') {
      steps {
        sh '''docker build -t $DOCKER_IMAGES .

docker login -u $DOCKER_USER -p $DOCKER_PASSWORD

docker push $DOCKER_IMAGES'''
      }
    }
  }
  environment {
    DOCKER_IMAGES = 'hhy5861/kong-rbac'
    DOCKER_USER = 'hhy5861'
    DOCKER_PASSWORD = 'tlslpc147852369'
  }
}