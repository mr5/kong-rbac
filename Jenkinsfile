pipeline {
  agent {
    docker {
      image 'hhy5861/kong-rbac'
    }
  }
  stages {
    stage('build') {
      steps {
        sh '''
          docker login -u %DOCKER_USER% -p %DOCKER_PASSWORD%
          docker build -t %DOCKER_IMAGES%
          docker push %DOCKER_IMAGES%
        '''
      }
    }
  }
  environment {
    DOCKER_IMAGES = 'hhy5861/kong-rbac'
    DOCKER_USER = 'hhy5861'
    DOCKER_PASSWORD = 'tlslpc147852369'
  }
}