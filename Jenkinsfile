pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t hhy5861/kong-rbac .'
            }
        }
        stage('deploy-dev') {
            steps {
              sh 'docker run -d --name kong \
              --name some-kong \
              --restart=always \
              -e "KONG_DATABASE=postgres" \
              -e "KONG_PG_HOST=192.168.31.243" \
              -e "KONG_CASSANDRA_CONTACT_POINTS=192.168.31.243" \
              -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
              -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
              -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
              -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
              -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
              -e "KONG_ADMIN_LISTEN_SSL=0.0.0.0:8444" \
              -p 8000:8000 \
              -p 8443:8443 \
              -p 8001:8001 \
              -p 8444:8444 \
              hhy5861/kong-rbac'
          }
        }
    }
}