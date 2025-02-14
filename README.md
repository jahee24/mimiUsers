📌 미미-노트북 대여 시스템

미미팀은 CI/CD를 배우고 실제 서비스를 배포하여 사용할 수 있도록 경험하기 위해 미미-노트북 대여 시스템을 구축하였습니다. 해당 서비스는 무상으로 노트북을 대여할 수 있도록 지원하며, 자동화된 빌드 및 배포 환경을 구성하여 운영됩니다.

🚀 기술 스택

운영체제: Ubuntu (가상 서버)

컨테이너화: Docker

저장소: GitHub (Ops, Actions 활용)

CI/CD 도구: Jenkins, ArgoCD

오케스트레이션: Kubernetes

백엔드: Spring Boot

데이터베이스: MySQL

🔧 빌드 및 배포

📍 Docker 빌드

애플리케이션을 컨테이너 이미지로 빌드합니다.

# Build Stage 
FROM gradle:8.11.1-jdk17 AS build  

WORKDIR /myapp  
COPY . /myapp  

RUN chmod +x /myapp/gradlew  
RUN /myapp/gradlew clean build --no-daemon -x test  

# Run Stage  
FROM openjdk:17-alpine  
WORKDIR /myapp  

COPY --from=build /myapp/build/libs/*SNAPSHOT.jar /myapp/mimiRental.jar  

EXPOSE 5678  
ENTRYPOINT ["java", "-jar", "/myapp/mimiRental.jar"]  

📍 CI/CD 자동화 (Jenkins Pipeline)

pipeline {
    agent any
    environment {
        APP_REPO_URL = 'https://github.com/jahee24/mimiUsers.git'
        GITHUB_CREDENTIAL_ID = 'githubhook_ID'
        DOCKERHUB_CREDENTIAL_ID = 'docker-hub-access'
        DOCKERHUB_REPOSITORY_IMAGE = 'jahee24/mimi-user'
        DOCKERHUB_TAG = "v2.${env.BUILD_NUMBER}"
    }
    stages {
        stage("gitclone") {
            steps {
                git branch: 'develop', 
                    credentialsId: 'githubhook_ID', 
                    url: 'https://github.com/jahee24/mimiUsers.git'
            }
        }
        stage("dockerbuild") {
            steps {
                sh 'docker build -t $DOCKERHUB_REPOSITORY_IMAGE:$DOCKERHUB_TAG .'
            }
        }
        stage("dockerpush") {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIAL_ID) {
                        def myimage = docker.image("$DOCKERHUB_REPOSITORY_IMAGE:$DOCKERHUB_TAG")
                        myimage.push()
                    }
                }
            }
        }
    }
}

📍 Kubernetes 배포

애플리케이션을 Kubernetes 클러스터에 배포합니다.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: rental
  namespace: mimiproject
spec:
  replicas: 1
  selector:
    matchLabels:
      project: mimirental
  template:
    metadata:
      labels:
        project: mimirental
    spec:
      containers:
        - name: rental
          image: daul0519/mimirental:v.1.3
          ports:
            - containerPort: 5678
          env:
            - name: DB_HOST
              value: "mysql-service"
            - name: DB_NAME
              value: "mimi"
            - name: DB_USER
              value: "mytest"
            - name: DB_PASSWORD
              value: "1234"
            - name: SPRING_DATASOURCE_URL
              value: "jdbc:mysql://10.104.200.22:3306/mimi"
---
apiVersion: v1
kind: Service
metadata:
  name: rental-service
  namespace: mimiproject
spec:
  type: LoadBalancer
  selector:
    project: mimirental
  ports:
    - port: 5678
      targetPort: 5678

📍 배포 명령어

kubectl apply -f mimi-service.yaml

📢 결론

미미-노트북 대여 시스템은 Jenkins, Docker, ArgoCD, Kubernetes를 활용하여 완전 자동화된 CI/CD 환경에서 배포됩니다. 해당 문서를 통해 팀원들이 쉽게 프로젝트를 빌드하고 배포할 수 있도록 가이드합니다.
