# AKS에 Prometheus와 Grafana 설치

- Azure AKS는 관리형 쿠버네티스 서비스이다. Azure는 Azure monitor를 통해 쿠버네티스 모니터링을 제공하지만, 요금이 발생한다. 따라서 이 시도는 비용을 절약하기 위한 것이다. 본 설치 문서는 아래 링크들을 참조하여 작성하였다. 거의 날로 먹은 셈이다. 기여하신 분들께 감사드린다. 잘 쓰겠다.

install : https://github.com/sohwaje/AKS-Monitoring-Tool, https://www.youtube.com/watch?v=XrGN2UvVPv0
grafana dashboard : https://grafana.com/grafana/dashboards/13770

##### Step: -
 1. git clone을 통해 리포지토리를 다운로드 한다.
 ```
 git clone https://github.com/sohwaje/AKS-Monitoring-Tool.git
 ```

 2. Azure cli를 설정한다.
 ```
 az login
 az account list -o table
 az account set --subscription <subscription ID>
 az aks get-credentials -n <aks_name> -g <resource_group_name>
 ```

 3. 쉘스크립트를 실행하여 helm 패키지로 설치(스크립트 설치 순서는 다음과 같다.)
  - 네임스페이스 생성
  - prometheus 설치
  - grafana 설치
  - prometheus portforward
  - grafana portforward(공인 IP가 설정되어 있어 불필요할 수도 있다.)
 ```
 sh install.sh or chmod +x install.sh && ./install.sh

 ```
***주의***
- 클러스터가 rbac 즉, 자격증명을 사용할 때 반드시 스크립트에서 아래와 같이 'rbac.create=true'로 변경한다.
```
helm install prometheus . --namespace monitoring --set rbac.create=false
```
