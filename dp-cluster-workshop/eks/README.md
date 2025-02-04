Table of Contents
=================
<!-- TOC -->
* [Table of Contents](#table-of-contents)
* [TIBCO Data Plane Cluster Workshop](#tibco-data-plane-cluster-workshop)
  * [Introduction](#introduction)
  * [Command Line Tools needed](#command-line-tools-needed)
  * [Recommended IAM Policies](#recommended-iam-policies)
  * [Create EKS cluster](#create-eks-cluster)
  * [Generate kubeconfig to connect to EKS cluster](#generate-kubeconfig-to-connect-to-eks-cluster)
  * [Install common third party tools](#install-common-third-party-tools)
  * [Install Ingress Controller, Storage class](#install-ingress-controller-storage-class-)
    * [Setup DNS](#setup-dns)
    * [Setup EFS](#setup-efs)
    * [Storage class](#storage-class)
  * [Install Observability tools](#install-observability-tools)
    * [Install Elastic stack](#install-elastic-stack)
    * [Install Prometheus stack](#install-prometheus-stack)
    * [Install Opentelemetry Collector for metrics](#install-opentelemetry-collector-for-metrics)
  * [Information needed to be set on TIBCO Control Plane](#information-needed-to-be-set-on-tibco-control-plane)
  * [Clean up](#clean-up)
<!-- TOC -->

# TIBCO Data Plane Cluster Workshop

The goal of this workshop is to provide a hands-on experience to deploy a TIBCO Data Plane cluster in AWS. This is the prerequisite for the TIBCO Data Plane.

## Introduction

In order to deploy TIBCO Data Plane, you need to have a Kubernetes cluster and install the necessary tools. This workshop will guide you to create a Kubernetes cluster in AWS and install the necessary tools.

## Command Line Tools needed

We are running the steps in a MacBook Pro. The following tools are installed using [brew](https://brew.sh/): 
* envsubst
* yq (v4.35.2)
* bash (5.2.15)
* aws (aws-cli/2.13.27)
* eksctl (0.162.0)
* kubectl (v1.28.3)
* helm (v3.13.1)

## Recommended IAM Policies
It is recommeded to have the [Minimum IAM Policies](https://eksctl.io/usage/minimum-iam-policies/ attached to the role which is being used for the cluster creation.
## Create EKS cluster

In this section, we will use [eksctl tool](https://eksctl.io/) to create an EKS cluster. This tool is recommended by AWS as the official tool to create EKS cluster.

In the context of eksctl tool; they have a yaml file called `ClusterConfig object`. 
This yaml file contains all the information needed to create an EKS cluster. 
We have created a yaml file [eksctl-recipe.yaml](eksctl-recipe.yaml) for our workshop to bring up an EKS cluster for TIBCO data plane.
We can use the following command to create an EKS cluster in your AWS account. 

```bash 
export DP_CLUSTER_NAME=dp-cluster
export DP_VPC_CIDR="10.200.0.0/16"
export AWS_REGION=us-west-2
cat eksctl-recipe.yaml | envsubst | eksctl create cluster -f -
```

It will take around 30 minutes to create an empty EKS cluster. 

## Generate kubeconfig to connect to EKS cluster

We can use the following command to generate kubeconfig file.
```bash
export AWS_REGION=us-west-2
export DP_CLUSTER_NAME=dp-cluster
aws eks update-kubeconfig --region ${AWS_REGION} --name ${DP_CLUSTER_NAME} --kubeconfig ${DP_CLUSTER_NAME}.yaml
```

And check the connection to EKS cluster.
```bash
export KUBECONFIG=${DP_CLUSTER_NAME}.yaml
kubectl get nodes
```

## Install common third party tools

Before we deploy ingress or observability tools on an empty EKS cluster; we need to install some basic tools. 
* [cert-manager](https://cert-manager.io/docs/installation/helm/)
* [external-dns](https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
* [aws-load-balancer-controller](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
* [metrics-server](https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server)

<details>

<summary>We can use the following commands to install these tools......</summary>

```bash
# install cert-manager
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n cert-manager cert-manager cert-manager \
  --repo "https://charts.jetstack.io" --version "v1.12.3" -f - <<EOF
installCRDs: true
serviceAccount:
  create: false
  name: cert-manager
EOF

# install external-dns
export MAIN_INGRESS_CONTROLLER=alb
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n external-dns-system external-dns external-dns \
  --repo "https://kubernetes-sigs.github.io/external-dns" --version "1.13.0" -f - <<EOF
serviceAccount:
  create: false
  name: external-dns 
extraArgs:
  # add filter to only sync only public Ingresses with this annotation
  - "--annotation-filter=kubernetes.io/ingress.class=${MAIN_INGRESS_CONTROLLER}"
EOF

# install aws-load-balancer-controller
export DP_CLUSTER_NAME=dp-cluster
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n kube-system aws-load-balancer-controller aws-load-balancer-controller \
  --repo "https://aws.github.io/eks-charts" --version "1.6.0" -f - <<EOF
clusterName: ${DP_CLUSTER_NAME}
serviceAccount:
  create: false
  name: aws-load-balancer-controller
EOF

# install metrics-server
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n kube-system metrics-server metrics-server \
  --repo "https://kubernetes-sigs.github.io/metrics-server" --version "3.11.0" -f - <<EOF
clusterName: ${DP_CLUSTER_NAME}
serviceAccount:
  create: true
  name: metrics-server
EOF
```
</details>

<details>

<summary>Sample output of third party helm charts that we have installed in the EKS cluster...</summary>

```bash
$ helm ls -A -a
NAME                        	NAMESPACE          	REVISION	UPDATED                             	STATUS  	CHART                             	APP VERSION
aws-load-balancer-controller	kube-system        	1       	2023-10-23 12:17:13.149673 -0500 CDT	deployed	aws-load-balancer-controller-1.6.0	v2.6.0
cert-manager                	cert-manager       	2       	2023-10-23 12:10:33.504296 -0500 CDT	deployed	cert-manager-v1.12.3              	v1.12.3
external-dns                	external-dns-system	1       	2023-10-23 12:13:04.39863 -0500 CDT 	deployed	external-dns-1.13.0               	0.13.5
metrics-server              	kube-system        	1       	2023-10-23 12:19:14.648056 -0500 CDT	deployed	metrics-server-3.11.0             	0.6.4
```
</details>

## Install Ingress Controller, Storage class 

In this section, we will install ingress controller and storage class. We have made a helm chart called `dp-config-aws` that encapsulates the installation of ingress controller and storage class. 
It will create the following resources:
* a main ingress object which will be able to create AWS alb and act as a main ingress for DP cluster
* annotation for external-dns to create DNS record for the main ingress
* a storage class for EBS
* a storage class for EFS

### Setup DNS
For this workshop we will use `dp-workshop.dataplanes.pro` as the domain name. We will use `*.dp1.dp-workshop.dataplanes.pro` as the wildcard domain name for all the DP capabilities.
We are using the following services in this workshop:
* [Amazon Route 53](https://aws.amazon.com/route53/): to manage DNS. We register `dp-workshop.dataplanes.pro` in Route 53. And give permission to external-dns to add new record.
* [AWS Certificate Manager (ACM)](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html): to manage SSL certificate. We will create a wildcard certificate for `*.dp1.dp-workshop.dataplanes.pro` in ACM.
* aws-load-balancer-controller: to create AWS ALB. It will automatically create AWS ALB and add SSL certificate to ALB.
* external-dns: to create DNS record in Route 53. It will automatically create DNS record for ingress objects.

For this workshop work; you will need to 
* register a domain name in Route 53. You can follow this [link](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html) to register a domain name in Route 53.
* create a wildcard certificate in ACM. You can follow this [link](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html) to create a wildcard certificate in ACM.

### Setup EFS
Before deploy `dp-config-aws`; we need to set up AWS EFS. For more information about EFS, please refer: 
* workshop to create EFS: [link](https://archive.eksworkshop.com/beginner/190_efs/launching-efs/)
* create EFS in AWS console: [link](https://docs.aws.amazon.com/efs/latest/ug/gs-step-two-create-efs-resources.html)
* create EFS with scripts: [link](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md)

We provide an [EFS creation script](create-efs.sh) to create EFS. 
```bash
export DP_CLUSTER_NAME=dp-cluster
./create-efs.sh ${DP_CLUSTER_NAME}
```

After running above script; we will get an EFS ID output like `fs-0ec1c745c10d523f6`. We will need to use this value to deploy `dp-config-aws` helm chart.

```bash
export TIBCO_DP_HELM_CHART_REPO=https://syan-tibco.github.io/tp-helm-charts
export DP_DOMAIN=dp1.dp-workshop.dataplanes.pro
export DP_EBS_ENABLED=true
export DP_EFS_ENABLED=true
export DP_EFS_ID="fs-0ec1c745c10d523f6"
## following section is required to send traces using nginx
## uncomment the below commented section to run/re-run the command, once DP_NAMESPACE is available
#export DP_NAMESPACE=""

helm upgrade --install --wait --timeout 1h --create-namespace \
  -n ingress-system dp-config-aws dp-config-aws \
  --repo "${TIBCO_DP_HELM_CHART_REPO}" --version "1.0.17" -f - <<EOF
dns:
  domain: "${DP_DOMAIN}"
httpIngress:
  annotations:
    alb.ingress.kubernetes.io/group.name: "${DP_DOMAIN}"
    external-dns.alpha.kubernetes.io/hostname: "*.${DP_DOMAIN}"
    # this will be used for external-dns annotation filter
    kubernetes.io/ingress.class: alb
storageClass:
  ebs:
    enabled: ${DP_EBS_ENABLED}
  efs:
    enabled: ${DP_EFS_ENABLED}
    parameters:
      fileSystemId: "${DP_EFS_ID}"
ingress-nginx:
  controller:
    config:
      # required by apps swagger
      use-forwarded-headers: "true"
## following section is required to send traces using nginx
## uncomment the below commented section to run/re-run the command, once DP_NAMESPACE is available
#       enable-opentelemetry: "true"
#       log-level: debug
#       opentelemetry-config: /etc/nginx/opentelemetry.toml
#       opentelemetry-operation-name: HTTP $request_method $service_name $uri
#       opentelemetry-trust-incoming-span: "true"
#       otel-max-export-batch-size: "512"
#       otel-max-queuesize: "2048"
#       otel-sampler: AlwaysOn
#       otel-sampler-parent-based: "false"
#       otel-sampler-ratio: "1.0"
#       otel-schedule-delay-millis: "5000"
#       otel-service-name: nginx-proxy
#       otlp-collector-host: otel-userapp.${DP_NAMESPACE}.svc
#       otlp-collector-port: "4317"
#     opentelemetry:
#       enabled: true
EOF  
```

Use the following command to get the ingress class name.
```bash
$ kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
alb     ingress.k8s.aws/alb    <none>       7h12m
nginx   k8s.io/ingress-nginx   <none>       7h11m
```

The `nginx` ingress class is the main ingress that DP will use. The `alb` ingress class is used by AWS ALB ingress controller.

> [!IMPORTANT]
> You will need to provide this ingress class name i.e. nginx to TIBCO Control Plane when you deploy capability.

### Storage class

Use the following command to get the storage class name.

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ebs-gp3         ebs.csi.aws.com         Retain          WaitForFirstConsumer   true                   7h17m
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  7h17m
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  7h41m
```

We have some scripts in the recipe to create and setup EFS. The `dp-config-aws` helm chart will create all these storage classes.
* `ebs-gp3` is the storage class for EBS. This is used for
  * storage class for data when provision EMS capability
* `efs-sc` is the storage class for EFS. This is used for
  * artifactmanager when we provision BWCE capability
  * storage class for log when we provision EMS capability
* `gp2` is the default storage class for EKS. AWS create it by default and don't recommend to use it.

> [!IMPORTANT]
> You will need to provide this storage class name to TIBCO Control Plane when you deploy capability.

## Install Observability tools

### Install Elastic stack

<details>

<summary>Use the following command to install Elastic stack...</summary>

```bash
# install eck-operator
helm upgrade --install --wait --timeout 1h --create-namespace -n elastic-system eck-operator eck-operator --repo "https://helm.elastic.co" --version "2.9.0"

# install dp-config-es
export TIBCO_DP_HELM_CHART_REPO=https://syan-tibco.github.io/tp-helm-charts
export DP_DOMAIN=dp1.dp-workshop.dataplanes.pro
export DP_ES_RELEASE_NAME=dp-config-es
export DP_INGRESS_CLASS=nginx
export DP_STORAGE_CLASS=ebs-gp3

helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n elastic-system dp-config-es ${DP_ES_RELEASE_NAME} \
  --repo "${TIBCO_DP_HELM_CHART_REPO}" --version "1.0.13" -f - <<EOF
domain: ${DP_DOMAIN}
es:
  version: "8.9.1"
  ingress:
    ingressClassName: ${DP_INGRESS_CLASS}
    service: ${DP_ES_RELEASE_NAME}-es-http
  storage:
    name: ${DP_STORAGE_CLASS}
kibana:
  version: "8.9.1"
  ingress:
    ingressClassName: ${DP_INGRESS_CLASS}
    service: ${DP_ES_RELEASE_NAME}-kb-http
apm:
  enabled: true
  version: "8.9.1"
  ingress:
    ingressClassName: ${DP_INGRESS_CLASS}
    service: ${DP_ES_RELEASE_NAME}-apm-http
EOF
```
</details>

Use this command to get the host URL for Kibana
```bash
kubectl get ingress -n elastic-system dp-config-es-kibana -oyaml | yq eval '.spec.rules[0].host'
```

The username is normally `elastic`. We can use the following command to get the password.
```bash
kubectl get secret dp-config-es-es-elastic-user -n elastic-system -o jsonpath="{.data.elastic}" | base64 --decode; echo
```

### Install Prometheus stack

<details>

<summary>Use the following command to install Prometheus stack...</summary>

```bash
# install prometheus stack
export DP_DOMAIN=dp1.dp-workshop.dataplanes.pro
export DP_INGRESS_CLASS=nginx

helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n prometheus-system kube-prometheus-stack kube-prometheus-stack \
  --repo "https://prometheus-community.github.io/helm-charts" --version "48.3.4" -f <(envsubst '${DP_DOMAIN}, ${DP_INGRESS_CLASS}' <<'EOF'
grafana:
  plugins:
    - grafana-piechart-panel
  ingress:
    enabled: true
    ingressClassName: ${DP_INGRESS_CLASS}
    hosts:
    - grafana.${DP_DOMAIN}
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
    remoteWriteDashboards: true
    additionalScrapeConfigs:
    - job_name: otel-collector
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: keep
        regex: "true"
        source_labels:
        - __meta_kubernetes_pod_label_prometheus_io_scrape
      - action: keep
        regex: "infra"
        source_labels:
        - __meta_kubernetes_pod_label_platform_tibco_com_workload_type
      - action: keepequal
        source_labels: [__meta_kubernetes_pod_container_port_number]
        target_label: __meta_kubernetes_pod_label_prometheus_io_port
      - action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_pod_label_prometheus_io_port
        target_label: __address__
      - source_labels: [__meta_kubernetes_pod_label_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
        replacement: /$1
  ingress:
    enabled: true
    ingressClassName: ${DP_INGRESS_CLASS}
    hosts:
    - prometheus-internal.${DP_DOMAIN}
EOF
)
```
</details>

Use this command to get the host URL for Kibana
```bash
kubectl get ingress -n prometheus-system kube-prometheus-stack-grafana -oyaml | yq eval '.spec.rules[0].host'
```

The username is `admin`. And Prometheus Operator use fixed password: `prom-operator`.

### Install Opentelemetry Collector for metrics

<details>

<summary>Use the following command to install Opentelemetry Collector for metrics...</summary>

```bash
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n prometheus-system otel-collector-daemon opentelemetry-collector \
  --repo "https://open-telemetry.github.io/opentelemetry-helm-charts" --version "0.72.0" -f - <<EOF
mode: "daemonset"
fullnameOverride: otel-kubelet-stats
podLabels:
  platform.tibco.com/workload-type: "infra"
  networking.platform.tibco.com/kubernetes-api: enable
  egress.networking.platform.tibco.com/internet-all: enable
  prometheus.io/scrape: "true"
  prometheus.io/path: "metrics"
  prometheus.io/port: "4319"
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 15
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
serviceAccount:
  create: true
clusterRole:
  create: true
  rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["get", "watch", "list"]
  - apiGroups: [""]
    resources: ["nodes/stats", "nodes/proxy"]
    verbs: ["get"]
extraEnvs:
  - name: KUBE_NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
ports:
  metrics:
    enabled: true
    containerPort: 8888
    servicePort: 8888
    hostPort: 8888
    protocol: TCP
  prometheus:
    enabled: true
    containerPort: 4319
    servicePort: 4319
    hostPort: 4319
    protocol: TCP
config:
  receivers:
    kubeletstats/user-app:
      collection_interval: 20s
      auth_type: "serviceAccount"
      endpoint: "https://${env:KUBE_NODE_NAME}:10250"
      insecure_skip_verify: true
      metric_groups:
        - pod
      extra_metadata_labels:
        - container.id
      metrics:
        k8s.pod.cpu_limit_utilization:
          enabled: true
        k8s.pod.memory_limit_utilization:
          enabled: true
        k8s.pod.filesystem.available:
          enabled: false
        k8s.pod.filesystem.capacity:
          enabled: false
        k8s.pod.filesystem.usage:
          enabled: false
        k8s.pod.memory.major_page_faults:
          enabled: false
        k8s.pod.memory.page_faults:
          enabled: false
        k8s.pod.memory.rss:
          enabled: false
        k8s.pod.memory.working_set:
          enabled: false
  processors:
    memory_limiter:
      check_interval: 5s
      limit_percentage: 80
      spike_limit_percentage: 25
    batch: {}
    k8sattributes/kubeletstats:
      auth_type: "serviceAccount"
      passthrough: false
      extract:
        metadata:
          - k8s.pod.name
          - k8s.pod.uid
          - k8s.namespace.name
        annotations:
          - tag_name: connectors
            key: platform.tibco.com/connectors
            from: pod
        labels:
          - tag_name: app_id
            key: platform.tibco.com/app-id
            from: pod
          - tag_name: app_type
            key: platform.tibco.com/app-type
            from: pod
          - tag_name: dataplane_id
            key: platform.tibco.com/dataplane-id
            from: pod
          - tag_name: workload_type
            key: platform.tibco.com/workload-type
            from: pod
          - tag_name: app_name
            key: platform.tibco.com/app-name
            from: pod
          - tag_name: app_version
            key: platform.tibco.com/app-version
            from: pod
          - tag_name: app_tags
            key: platform.tibco.com/tags
            from: pod
      pod_association:
        - sources:
            - from: resource_attribute
              name: k8s.pod.uid
    filter/user-app:
      metrics:
        include:
          match_type: strict
          resource_attributes:
            - key: workload_type
              value: user-app
    transform/metrics:
      metric_statements:
      - context: datapoint
        statements:
          - set(attributes["pod_name"], resource.attributes["k8s.pod.name"])
          - set(attributes["pod_namespace"], resource.attributes["k8s.namespace.name"])
          - set(attributes["app_id"], resource.attributes["app_id"])
          - set(attributes["app_type"], resource.attributes["app_type"])
          - set(attributes["dataplane_id"], resource.attributes["dataplane_id"])
          - set(attributes["workload_type"], resource.attributes["workload_type"])
          - set(attributes["app_tags"], resource.attributes["app_tags"])
          - set(attributes["app_name"], resource.attributes["app_name"])
          - set(attributes["app_version"], resource.attributes["app_version"])
          - set(attributes["connectors"], resource.attributes["connectors"])
    filter/include:
      metrics:
        include:
          match_type: regexp
          metric_names:
            - .*memory.*
            - .*cpu.*
  exporters:
    prometheus/user:
      endpoint: 0.0.0.0:4319
      enable_open_metrics: true
      resource_to_telemetry_conversion:
        enabled: true
  extensions:
    health_check: {}
    memory_ballast:
      size_in_percentage: 40
  service:
    telemetry:
      logs: {}
      metrics:
        address: :8888
    extensions:
      - health_check
      - memory_ballast
    pipelines:
      logs: null
      traces: null
      metrics:
        receivers:
          - kubeletstats/user-app
        processors:
          - k8sattributes/kubeletstats
          - filter/user-app
          - filter/include
          - transform/metrics
          - batch
        exporters:
          - prometheus/user
EOF
```
</details>

## Information needed to be set on TIBCO Control Plane

You can get base FQDN by running the following command:
```bash
kubectl get ingress -n ingress-system nginx |  awk 'NR==2 { print $3 }'
```

| Name                 | Sample value                                                                     | Notes                                                                     |
|:---------------------|:---------------------------------------------------------------------------------|:--------------------------------------------------------------------------|
| VPC_CIDR             | 10.200.0.0/16                                                                    | you can find this from eks recipe                                         |
| ingress class name   | nginx                                                                            | this is used for BWCE                                                     |
| EFS storage class    | efs-sc                                                                           | this is used for BWCE EFS storage                                         |
| EBS storage class    | ebs-gp3                                                                          | this is used for EMS messaging                                            |
| BW FQDN              | bwce.\<base FQDN\>                                                               | this is the main domain plus any name you want to use for this capability |
| User app log index   | user-app-1                                                                       | this comes from dp-config-es index template                               |
| service ES index     | service-1                                                                        | this comes from dp-config-es index template                               |
| ES internal endpoint | https://dp-config-es-es-http.elastic-system.svc.cluster.local:9200               | this comes from ES service                                                |
| ES public endpoint   | https://elastic.\<base FQDN\>                                                    | this comes from ES ingress                                                |
| ES password          | xxx                                                                              | see above ES password                                                     |
| tracing server host  | https://dp-config-es-es-http.elastic-system.svc.cluster.local:9200               | same as elastic internal endpoint                                         |
| Prometheus endpoint  | http://kube-prometheus-stack-prometheus.prometheus-system.svc.cluster.local:9090 | this comes from Prometheus service                                        |
| Grafana endpoint  | https://grafana.\<base FQDN\> | this comes from Grafana service                                        |

## Clean up

We provide a helper [clean-up](clean-up.sh) to delete the EKS cluster.
```bash
export DP_CLUSTER_NAME=dp-cluster
./clean-up.sh ${DP_CLUSTER_NAME}
```
