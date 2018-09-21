---
layout: post
title: Using pod security policies with kubeadm
categories: k8s
---

## Purpose
Illustrate using [pod security policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) with a [kubeadm](https://github.com/kubernetes/kubeadm) installation of kubernetes

Pod security policies are a mechanism to restrict what a container can do when run on kubernetes such as preventing running as privileged containers, running with host networking etc.

Read the [docs](https://pmcgrath.net/using-pod-security-policies-with-kubeadm) to see how this can be used to improve security

I struggled to find any information on bootstrapping a kubeadm cluster with the same, hence this content



## TLDR
This post is very long so I can do a full illustration, in short you need to
- On master run kubeadm init with the PodSecurityPolicy admission controller enabled
- Add some pod security policies with RBAC config - enough to allow CNI and DNS etc. to start
	- CNI daemonsets will not start without this
- Apply your CNI provider which can use one of the previously created pod security policies
- Complete configuring the cluster adding nodes via kubeadm join
- As you add more workloads to the cluster check if you need additional pod security policies and RBAC configuration for the same



## What we will do
This is the list of steps I took to get pod security policies running on a kubeadm installation
- Configure the pod security policy admission [controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#podsecuritypolicy) for master init
- Configure some pod security policies for the control plane components
- Configure a CNI provider - Will use flannel here

Will then use the following to demo some other pod security policy scenarios
- Install an nginx-ingress controller which has some specfic requirements - This is just to illustrate adding additional policies
- Install a regular service that has no specific pod security policy requirements - Based on [httpbin.org](https://hub.docker.com/r/kennethreitz/httpbin/)



## Environment
- Will just illustrate on a single node rather than a multi-node cluster with HA
- Ubuntu
	- Swap off as required by kubeadm
	- Timezone configured for UTC
- Docker
	- Assumes current user is in the docker group
- kubernetes 1.11.3 - with RBAC



## Prepare master
Follow the instructions to install [kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)

Lets install [jq](https://stedolan.github.io/jq/manual/) which we will use for some json output processing
```
sudo apt-get update
sudo apt-get install -y jq
```

Verify kubeadm version
```
sudo kubeadm version
```

Create a directory somewhere for the content we will create below, all below instructions assume you are in this directory
```
mkdir ~/psp-inv
cd ~/psp-inv
```



## kubeadm config file
Will create this file and use it for **kubeadm init** on the master

Create a **kubeadm-config.yaml** file with this content - note we have to specify the podSubnet of 10.244.0.0/16 for flannel

Note this file is minimal for this demo and if you use a later version of kubeadm you may need to alter the apiVersion
```
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
apiServerExtraArgs:
  enable-admission-plugins: PodSecurityPolicy
controllerManagerExtraArgs:
  address: 0.0.0.0
kubernetesVersion: v1.11.3
networking:
  podSubnet: 10.244.0.0/16
schedulerExtraArgs:
  address: 0.0.0.0
```



## Master init
```
sudo kubeadm init --config kubeadm-config.yaml
```

Follow the instructions from the above command output to get your own copy of the kubeconfig file

If you want to add worker nodes to the cluster, note the join message

Lets check the master node status with
```
kubectl get nodes

NAME                    STATUS     ROLES     AGE       VERSION
pmcgrath-k8s-master     NotReady   master    1m        v1.11.3
```

So the node is not ready as it is waiting for CNI

Lets check the pods
```
kubectl get pods --all-namespaces
No resources found.
```
So none appear to be running, would normally see pods with some pending if we had not enabled the pod security policy admission control

Lets check docker
```
docker container ls --format "{{ .Names }}"

k8s_kube-scheduler_kube-scheduler-pmcgrath-k8s-master_kube-system_a00c35e56ebd0bdfcd77d53674a5d2a1_0
k8s_kube-controller-manager_kube-controller-manager-pmcgrath-k8s-master_kube-system_fd832ada507cef85e01885d1e1980c37_0
k8s_etcd_etcd-pmcgrath-k8s-master_kube-system_16a8af6b4a79e9b0f81092f85eab37cf_0
k8s_kube-apiserver_kube-apiserver-pmcgrath-k8s-master_kube-system_db201a8ecaf8e99623b425502a6ba627_0
k8s_POD_kube-controller-manager-pmcgrath-k8s-master_kube-system_fd832ada507cef85e01885d1e1980c37_0
k8s_POD_kube-scheduler-pmcgrath-k8s-master_kube-system_a00c35e56ebd0bdfcd77d53674a5d2a1_0
k8s_POD_kube-apiserver-pmcgrath-k8s-master_kube-system_db201a8ecaf8e99623b425502a6ba627_0
k8s_POD_etcd-pmcgrath-k8s-master_kube-system_16a8af6b4a79e9b0f81092f85eab37cf_0
```

So containers are running, but not showing up with kubectl

Lets check events
```
kubectl get events --namespace kube-system
```

will see something like  Error creating: pods "kube-proxy-" is forbidden: no providers available to validate pod request



## Configure pod security policies
I have went with configuring
- A default pod security policy that any workload can use, has no privileges and should be good for most workloads
	- Will create an RBAC ClusterRole
	- Will create an RBAC ClusterRoleBinding for any authenticated users
- A privileged pod security policy that I grant nodes and all service accounts in the kube-system namespace access to
	- Thinking is access to this namespace is restricted
	- Should only run k8s components in this namespace
	- Will create an RBAC ClusterRole
	- Will create an RBAC RoleBinding in the kube-system namespace

Create a **default-psp-with-rbac.yaml** file with this content
```
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
  name: default
spec:
  allowedCapabilities: []  # default set of capabilities are implicitly allowed
  allowPrivilegeEscalation: false
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  hostIPC: false
  hostNetwork: false
  hostPID: false
  privileged: false
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsNonRoot'
  supplementalGroups:
    rule: 'RunAsNonRoot'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  volumes:
  - 'configMap'
  - 'downwardAPI'
  - 'emptyDir'
  - 'persistentVolumeClaim'
  - 'projected'
  - 'secret'
  hostNetwork: false
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'

---

# Cluster role which grants access to the default pod security policy
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-psp
rules:
- apiGroups:
  - policy
  resourceNames:
  - default
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

# Cluster role binding for default pod security policy granting all authenticated users access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: default-psp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-psp
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:authenticated
```

Create a **privileged-psp-with-rbac.yaml** file with this content
```
# Should grant access to very few pods, i.e. kube-system system pods and possibly CNI pods
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    # See https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
  name: privileged
spec:
  allowedCapabilities:
  - '*'
  allowPrivilegeEscalation: true
  fsGroup:
    rule: 'RunAsAny'
  hostIPC: true
  hostNetwork: true
  hostPID: true
  hostPorts:
  - min: 0
    max: 65535
  privileged: true
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  volumes:
  - '*'

---

# Cluster role which grants access to the privileged pod security policy
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: privileged-psp
rules:
- apiGroups:
  - policy
  resourceNames:
  - privileged
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

# Role binding for kube-system - allow nodes and kube-system service accounts - should take care of CNI i.e. flannel running in the kube-system namespace
# Assumes access to the kube-system is restricted
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kube-system-psp
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: privileged-psp
subjects:
# For the kubeadm kube-system nodes
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
# For all service accounts in the kube-system namespace
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:kube-system
```

### Apply the above pod security policies with RBAC configuration
```
kubectl apply -f default-psp-with-rbac.yaml
kubectl apply -f privileged-psp-with-rbac.yaml
```

### Check
Control plane pods will turn up in a running state after some time, coredns pods will be pending - waiting on CNI
```
kubectl get pods --all-namespaces --output wide --watch
```

Control plane pods will start failing again until CNI is configured, as the node is still not ready

### Install flannel
See [here](https://github.com/coreos/flannel)

Will only be able to complete this as the **privileged** pod security policy will now exist and the flannel service account in the kube-system will be able to use

If using a different CNI provider you should use their installation instructions, will probably need to alter the podSubnet in the kubeadm-config.yaml file used for kubeadm init

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### Check
```
kubectl get pods --all-namespaces --output wide --watch
```

All pods will eventually get to a running status including coredns pod(s)

```
kubectl get nodes
```

Node is now ready

### Allow workloads on the master
If you want to spin up worker nodes, you can do so as normal using the **kubeadm join** command using the output from kubeadm init, skipping this here

Nothing special needed on worker nodes joining the cluster pod security policy wise

To allow workloads on the master node, as we are just trying to verify on a single node cluster
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```



## nginx ingress
Will use the manifest from [here](https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml)

This will create a new namespace and a single instance ingress controller, which is enough to illustrate additional pod security policies

### Namespace
Since the namespace will not yet exist, lets create so we can reference service accounts and create a role binding

```
kubectl create namespace ingress-nginx
```

### Lets create a pod security policy
This pod security policy is based on the deployment [manifest](https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml)

Create a file **nginx-ingress-psp-with-rbac.yaml** with this content
```
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    # Assumes apparmor available
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
  name: ingress-nginx
spec:
  # See nginx-ingress-controller deployment at https://github.com/kubernetes/ingress-nginx/blob/master/deploy/mandatory.yaml
  # See also https://github.com/kubernetes-incubator/kubespray/blob/master/roles/kubernetes-apps/ingress_controller/ingress_nginx/templates/psp-ingress-nginx.yml.j2
  allowedCapabilities:
  - NET_BIND_SERVICE
  allowPrivilegeEscalation: true
  fsGroup:
    rule: 'MustRunAs'
    ranges:
    - min: 1
      max: 65535
  hostIPC: false
  hostNetwork: false
  hostPID: false
  hostPorts:
  - min: 80
    max: 65535
  privileged: false
  readOnlyRootFilesystem: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
    ranges:
    - min: 33
      max: 65535
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
    # Forbid adding the root group.
    - min: 1
      max: 65535
  volumes:
  - 'configMap'
  - 'downwardAPI'
  - 'emptyDir'
  - 'projected'
  - 'secret'

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ingress-nginx-psp
  namespace: ingress-nginx
rules:
- apiGroups:
  - policy
  resourceNames:
  - ingress-nginx
  resources:
  - podsecuritypolicies
  verbs:
  - use

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ingress-nginx-psp
  namespace: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-nginx-psp
subjects:
# Lets cover default and nginx-ingress-serviceaccount service accounts
# Could have altered default-http-backend deployment to use the same service acccount to avoid granting the default service account access
- kind: ServiceAccount
  name: default
- kind: ServiceAccount
  name: nginx-ingress-serviceaccount
```

Lets apply
```
kubectl apply -f nginx-ingress-psp-with-rbac.yaml
```

### Create nginx-ingress workload
- Will remove the controller --publish-service arg as we do not need here

```
curl -s https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml | sed '/--publish-service/d'  | kubectl apply -f -
```

Check for pods
```
kubectl get pods --namespace ingress-nginx --watch
```

Can now see the pod security policy is attached with an annotation with
```
kubectl get pods --namespace ingress-nginx --selector app.kubernetes.io/name=ingress-nginx -o json | jq -r  '.items[0].metadata.annotations."kubernetes.io/psp"'
```



## Httpbin.org workload
Lets deploy a workload where the default pod security policy will suffice

Create a **httpbin.yaml** file with this content
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: httpbin
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: httpbin
  template:
    metadata:
      labels:
        app.kubernetes.io/name: httpbin
    spec:
      containers:
      - args: ["-b", "0.0.0.0:8080", "httpbin:app"]
        command: ["gunicorn"]
        image: docker.io/kennethreitz/httpbin:latest
        imagePullPolicy: Always
        name: httpbin
        ports:
        - containerPort: 8080
          name: http
      restartPolicy: Always

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: "nginx"
  labels:
    app.kubernetes.io/name: httpbin
  name: httpbin
spec:
  rules:
  - host: my.httpbin.com
    http:
      paths:
      - path:
        backend:
          serviceName: httpbin
          servicePort: 8080

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: httpbin
  name: httpbin
spec:
  ports:
  - name: http
    port: 8080
  selector:
    app.kubernetes.io/name: httpbin
```

Create namespace and run in workload
```
kubectl create namespace demo
kubectl apply --namespace demo -f httpbin.yaml
```

Lets check that the pod exists and the default policy was used
```
kubectl get pods --namespace demo

kubectl get pods --namespace demo --selector app.kubernetes.io/name=httpbin -o json | jq -r  '.items[0].metadata.annotations."kubernetes.io/psp"'
```


### Test workload
Will do so by calling via ingress controller pod instance - I have no ingress service for this demo

```
# Get nginx ingress controller pod IP
nginx_ip=$(kubectl get pods --namespace ingress-nginx --selector app.kubernetes.io/name=ingress-nginx --output json | jq -r .items[0].status.podIP)

# Test ingress and out httpbin workload
curl -H 'Host: my.httpbin.com' http://$nginx_ip/get
```



## Resets
If like me you mess this up regularly, you can reset and restart with

```
# Note: Will loose PKI also which is fine here as kubeadm master init will re-create
sudo kubeadm reset

# Should flush iptable rules after a kubeadm reset, see https://blog.heptio.com/properly-resetting-your-kubeadm-bootstrapped-cluster-nodes-heptioprotip-473bd0b824aa
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```



## Links
- [Documentation](https://kubernetes.io/docs/concepts/policy/pod-security-policy)
- [Github issues comment](https://github.com/kubernetes/kubernetes/issues/62566#issuecomment-381360838)
- [Security recommendations](https://github.com/freach/kubernetes-security-best-practice/tree/master/PSP)
- [GCE policies](https://github.com/kubernetes/kubernetes/tree/master/cluster/gce/addons/podsecuritypolicies)
