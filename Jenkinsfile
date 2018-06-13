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
                sh 'docker run -d --name some-kong \
                --restart=always \
                --link some-kong-postgres:kong-database \
                -e "KONG_DATABASE=postgres" \
                -e "KONG_PG_HOST=kong-database" \
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