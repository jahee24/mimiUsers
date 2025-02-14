# 📌 미미-노트북 대여 시스템: 빌드 및 배포 문서

![Mimi Laptop Rental](https://img.shields.io/badge/Mimi-Laptop%20Rental-blue.svg)

## 📝 개요

미미팀은 **CI/CD를 학습하고 실제 서비스를 배포하여 사용될 수 있도록 하는 경험**을 위해 **미미-노트북 대여 시스템**을 구축하였습니다. 이 시스템은 **무상으로 노트북을 대여**할 수 있도록 지원하며, 빌드 및 배포 과정을 설명합니다.

---

## 🚀 빌드 및 배포 개요

### 📌 사용 기술 및 도구

- **운영체제:** Ubuntu (가상 서버)
- **언어:** Java (Spring Boot)
- **빌드 도구:** Gradle
- **컨테이너화:** Docker
- **CI/CD 도구:** GitHub Actions, Jenkins, ArgoCD
- **배포 인프라:** Kubernetes
- **데이터베이스:** MySQL

### 🔄 CI/CD 개요

1. **GitHub**: 소스 코드 관리 및 CI/CD 트리거
2. **Jenkins**: 자동화된 빌드 및 Docker 이미지 생성, Docker Hub에 푸시
3. **Docker Hub**: 빌드된 이미지를 저장하고 Kubernetes에서 사용
4. **ArgoCD**: Kubernetes 클러스터에 자동 배포

---


## 🏗️ 빌드 프로세스

### 📂 Dockerfile을 이용한 빌드

```Dockerfile
# Build Stage
FROM gradle:8.11.1-jdk17 AS build

# 작업 디렉토리 생성
WORKDIR /myapp

# 프로젝트 전체 파일을 복사
COPY . /myapp

# Gradle 실행 권한 추가
RUN chmod +x /myapp/gradlew

# Gradle 빌드 실행 (테스트 제외)
RUN /myapp/gradlew clean build --no-daemon -x test

# Run Stage
FROM openjdk:17-alpine

# 작업 디렉토리 생성
WORKDIR /myapp

# 빌드된 JAR 파일 복사
COPY --from=build /myapp/build/libs/*SNAPSHOT.jar /myapp/mimiuser.jar

# 애플리케이션 실행 포트
EXPOSE 5679

# 애플리케이션 실행 명령어
ENTRYPOINT ["java", "-jar", "/myapp/mimiuser.jar"]
```

---

## ☸️ Kubernetes 배포

### 📜 배포 리소스 정의 (`mimi-app-service.yaml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rental
  namespace: mimiproject
spec:
  replicas: 1
  selector:
    matchLabels:
      project: mimiuser
  template:
    metadata:
      labels:
        project: mimiuser
    spec:
      containers:
        - name: rental
          image: daul0519/mimiuser:v1.3
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
```

### 🌐 Ingress 설정 (`ingress-setting.yaml`)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-setting
  namespace: mimiproject
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - backend:
              service:
                name: mimi-user
                port:
                  number: 5678
            path: /rental
            pathType: Prefix
```

---

## ⚙️ Jenkins CI/CD 파이프라인 (`Jenkinsfile`)
```groovy
pipeline {
    agent any
    environment {
        APP_REPO_URL = 'https://github.com/05Daul/mimiUsers.git'
        GITHUB_CREDENTIAL_ID = 'githubhook_ID'
        DOCKERHUB_CREDENTIAL_ID = 'docker-hub-access'
        DOCKERHUB_REPOSITORY_IMAGE = '05Daul/mimi-user'
        DOCKERHUB_TAG = "v2.${env.BUILD_NUMBER}"
    }
    stages {
        stage("Git Clone") {
            steps {
                git branch: 'develop', 
                    credentialsId: 'githubhook_ID', 
                    url: 'https://github.com/05Daul/mimiUsers.git'
            }
        }
        stage("Docker Build") {
            steps {
                sh 'docker build -t $DOCKERHUB_REPOSITORY_IMAGE:$DOCKERHUB_TAG .'
            }
        }
        stage("Docker Push") {
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
```

---

## ✅ 실행 및 검증 방법
```sh
# Kubernetes 배포
kubectl apply -f mimi-app-service.yaml
kubectl apply -f ingress-setting.yaml

# 배포 확인
kubectl get pods -n mimiproject
kubectl get svc -n mimiproject
```

---

## 🔧 트러블슈팅
### 🚨 빌드 오류 해결
- `gradlew: Permission denied`: `chmod +x gradlew` 실행 후 다시 빌드
- `docker: command not found`: Docker 설치 및 실행 여부 확인

### ⚠️ 배포 오류 해결
- Pod CrashLoopBackOff 발생 시 `kubectl describe pod <pod-name>`로 로그 확인
- `kubectl logs <pod-name>` 명령어로 오류 메시지 분석

---

## 🎯 프로젝트 정보
📌 **레포지토리:** [GitHub - 미미팀](https://github.com/jahee24/mimiUsers)  
📌 **Docker Hub:** [Mimi-User](https://hub.docker.com/r/daul0519/mimi-user)  
📌 **배포 환경:** Kubernetes + ArgoCD  
📌 **문의:** mimi.support@example.com  

