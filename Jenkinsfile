  pipeline {
    agent any

    tools {
      maven 'MyMaven'
    }
    triggers {
      githubPush() // 🔔 тригер на пуш у репозиторій
    }
    environment {
      VAULT_ADDR = 'http://localhost:8200'
      VAULT_TOKEN = credentials('vault-token') // Jenkins credentials ID
      VERSION = "v.1.0.${BUILD_NUMBER}"
      IMAGE_NAME = "spring-petclinic-devsecops"
    }

    stages {

      stage('Build & Unit Test') {
        steps {
          sh '''
            rm -rf zap-reports/zap_report.html snyk-report.html  trivy-report-lmh.html trivy-report-crit.html
            mvn clean verify
          '''
        }
      }

      stage('Static Analysis with SonarQube') {
        environment {
          SONAR_TOKEN = credentials('sonar-token') // Jenkins secret with ID 'sonar-token'
        }
        steps {
          script {
            withSonarQubeEnv('Sonar') {
              def scannerHome = tool name: 'Sonar', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
              sh """
                ${scannerHome}/bin/sonar-scanner \\
                  -Dsonar.projectKey=spring-petclinic \\
                  -Dsonar.projectName=spring-petclinic \\
                  -Dsonar.projectVersion=1.0 \\
                  -Dsonar.sources=src/main/java \\
                  -Dsonar.java.binaries=target/classes \\
                  -Dsonar.token=$SONAR_TOKEN
              """
            }
          }
        }
      }

      stage('Snyk Scan') {
        environment {
          SNYK_TOKEN = credentials('snyk-token')
        }
        steps {
          sh '''
            snyk auth $SNYK_TOKEN
            snyk test --all-projects --json | snyk-to-html -o snyk-report.html || true
          '''
        }
      }

      stage('Check Docker Access') {
        steps {
          sh 'docker version'
        }
      }

      stage('Build Docker Image') {
        steps {
          withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            script {
              docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-creds') {
                def image = docker.build("${DOCKER_USER}/${IMAGE_NAME}:${VERSION}", '--no-cache -f docker/Dockerfile .')
                image.push("${VERSION}")
              }
            }
          }
        }
      }

      stage('Trivy Vulnerability Scan') {
        steps {
          withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh '''
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
              trivy image -f template --template "@html.tpl" -o trivy-report-lmh.html --exit-code 0 --severity LOW,MEDIUM,HIGH $DOCKER_USER/$IMAGE_NAME:$VERSION
              trivy image -f template --template "@html.tpl" -o trivy-report-crit.html --exit-code 1 --severity CRITICAL $DOCKER_USER/$IMAGE_NAME:$VERSION || true
            '''
          }
        }
      }

      stage('Deploy to Test Environment') {
        steps {
          sh '''
            chmod +x scripts/export_env_from_vault_for_docker.sh
            ./scripts/export_env_from_vault_for_docker.sh
            
            export BUILD_VERSION=$VERSION

            docker compose -f docker/docker-compose-dev.yml down -v
            docker compose -f docker/docker-compose-dev.yml up -d
          '''
        }
      }

      stage('OWASP ZAP Scan') {
        steps {
          sh '''
            mkdir -p zap-reports
            chmod 777 zap-reports
            
            HOST_IP=$(ip addr show wlo1 | awk '/inet / {print $2}' | cut -d/ -f1)

            docker run --rm \
              -v "$PWD/zap-reports:/zap/wrk" \
              ghcr.io/zaproxy/zaproxy:stable \
              zap-baseline.py \
                -t http://$HOST_IP:8081 \
                -g /tmp/gen.conf \
                -r zap_report.html || true
          '''
        }
        post {
          always {
            archiveArtifacts artifacts: '**/*.html', allowEmptyArchive: true
          }
        }
      }
    }
  }
