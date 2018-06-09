pipeline {
  agent {
    docker {
      image 'hhy5861/kong-rbac'
    }

  }
  stages {
    stage('build') {
      steps {
        echo 'Hello build docker!'
      }
    }
  }
  environment {
    DOCKER_IMAGES = 'hhy5861/kong-rbac'
    DOCKER_USER = 'hhy5861'
    DOCKER_PASSWORD = 'tlslpc147852369'
  }
}