# AKS에 Prometheus와 Grafana 설치

- Azure AKS는 관리형 쿠버네티스 서비스이다. Azure는 Azure monitor를 통해 쿠버네티스 모니터링을 제공하지만, 요금이 발생한다. 따라서 이 시도는 비용을 절약하기 위한 것이다. 본 설치 문서는 아래 링크들을 참조하여 작성하였다.

install : https://www.youtube.com/watch?v=XrGN2UvVPv0, https://atouati.com/posts/2019/12/aks-monitoring-with-prometheus/, https://github.com/maheshkvis/AKS-Monitoring-Tool

prometheus-alertmanager : https://github.com/vipin-k/Kubernetes-Monitoring-with-Prometheus-, https://gruuuuu.github.io/cloud/monitoring-02/#

kubectl cheatsheet: https://kubernetes.io/ko/docs/reference/kubectl/cheatsheet/


grafana dashboard : https://grafana.com/grafana/dashboards/13770

##### Step: -
1. git clone을 통해 리포지토리를 다운로드 한다.
  ```
  git clone https://github.com/sohwaje/AKS-Monitoring-Tool.git
  ```

![Alt text](/image/aks-dir.PNG "디렉토리 구조")

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
* * *
# Alert Manager 설정
1. AKS-Monitoring-Tool/prometheus/values.yml 수정
 ```
 ## alertmanager ConfigMap entries
 alertmanagerFiles:
  alertmanager.yml:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'slack-notification'
      routes:
      - match:
          alertname: Watchdog
        receiver: 'slack-notification'
      - match_re:
          severity: '^(none|warning|critical)$'
        receiver: 'slack-notification'
    receivers:
      - name: 'slack-notification'
        slack_configs:
          - api_url: ''
            channel: '#smm'
  ```
2. 커스텀 rule 설정 예제(라인 )

  ```
  vi custom-rules.yml
  ```

  ```
  - alert: KubernetesApiClientErrors
    expr: (sum(rate(rest_client_requests_total{code=~"(4|5).."}[1m])) by (instance, job) / sum(rate(rest_client_requests_total[1m])) by (instance, job)) * 100 > 1
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: Kubernetes API client errors (instance {{ $labels.instance }})
      description: "Kubernetes API client is experiencing high error rate\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
  ```
3. helm upgrade
  ```
  helm upgrade prometheus . --namespace monitoring -f values.yaml -f custom-rules.yml
  ```

![Alt text](/image/prometheus_alert.PNG "Prometheus Alert")

4. alertmanager 포트포워딩
  ```
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=alertmanager" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward --address localhost,10.1.10.5 $POD_NAME 9093
  ```
