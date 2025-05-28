pipeline {
  agent any

  tools {
    maven 'MyMaven'
  }

  environment {
    VAULT_ADDR = 'http://localhost:8200'
    VAULT_TOKEN = credentials('vault-token') // Jenkins credentials ID
  }

  stages {

    // stage('Build & Unit Test') {
    //   steps {
    //     sh '''
    //       mvn clean verify
    //     '''
    //   }
    // }

    stage('Static Analysis with SonarQube') {
      environment {
        SONAR_TOKEN = credentials('sonar-token') // Jenkins secret with ID 'sonar-token'
      }
      steps {
        script {
          withSonarQubeEnv('Sonar') { // 'Sonar' is the Jenkins SonarQube server name
            def scannerHome = tool 'SonarScanner' // 'SonarScanner' is the Jenkins tool name
            sh '''#!/bin/bash
              export SONAR_TOKEN=$SONAR_TOKEN
              "SonarScanner/bin/sonar-scanner" \
                -Dsonar.projectKey=spring-petclinic \
                -Dsonar.projectName="spring-petclinic" \
                -Dsonar.projectVersion=1.0 \
                -Dsonar.sources=src/main/java \
                -Dsonar.java.binaries=target/classes
            '''
          }
        }
      }
    }

    stage('Snyk Scan') {
      environment {
        SNYK_TOKEN = credentials('snyk-token')
      }
      steps {
        snykSecurity(
          snykTokenId: 'snyk-token',
          targetFile: 'pom.xml',
          projectName: 'spring-petclinic',
          failOnIssues: false,
          monitorProjectOnBuild: true,
          severity: 'low',
          additionalArguments: '--all-projects'
        )
      }
    }

    stage('Check Docker Access') {
      steps {
        sh 'docker version'
      }
    }

    // stage('Build Docker Image') {
    //   steps {
    //     withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
    //       script {
    //         docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-creds') {
    //           def app = docker.build("${DOCKER_USER}/spring-petclinic:latest", '-f docker/Dockerfile .')
    //           app.push('latest')
    //         }
    //       }
    //     }
    //   }
    // }

    // stage('Trivy Vulnerability Scan') {
    //   steps {
    //     withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
    //       sh '''
    //         echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
    //         trivy image --exit-code 0 --severity LOW,MEDIUM,HIGH $DOCKER_USER/spring-petclinic:latest
    //         trivy image --exit-code 1 --severity CRITICAL $DOCKER_USER/spring-petclinic:latest || true
    //       '''
    //     }
    //   }
    // }

    // stage('Deploy to Test Environment') {
    //   steps {
    //     sh '''
    //       chmod +x scripts/export_env_from_vault_for_docker.sh
    //       ./scripts/export_env_from_vault_for_docker.sh
    //       docker compose down
    //       docker compose -f docker-compose.yml up -d
    //     '''
    //   }
    // }

    // stage('OWASP ZAP Scan') {
    //   steps {
    //     sh '''
    //       zap-baseline.py -t http://localhost:8081 -r zap_report.html || true
    //     '''
    //   }
    // }

  }

  post {
    always {
      archiveArtifacts artifacts: '**/*.html', allowEmptyArchive: true
    }
  }
}
