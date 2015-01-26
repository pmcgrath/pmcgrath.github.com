---
layout: post
title: Running an etcd cluster on localhost
categories: docker etcd
---

## Purpose
- Run a cluster on localhost while investigating etcd
- Use a [static](https://github.com/coreos/etcd/blob/master/Documentation/clustering.md#static) cluster (So we have no external dependecies for bootstrapping)


## Background information
- etcd [source](https://github.com/coreos/etcd)
- [How to use etcdctl and etcd coreos's distributed key value store](https://www.digitalocean.com/community/tutorials/how-to-use-etcdctl-and-etcd-coreos-s-distributed-key-value-stor://www.digitalocean.com/community/tutorials/how-to-use-etcdctl-and-etcd-coreos-s-distributed-key-value-store)
- etcd [clustering](https://github.com/coreos/etcd/blob/master/Documentation/clustering.md)
- etcd [documentation](https://github.com/coreos/etcd/tree/master/Documentation)
- [Consul](https://www.consul.io/) which is a very popular alternative


## Bootstrap
- Will use static bootstrapping
- Client connection port default is 2379 (Just supporting a single port per node), we will decerement the port for subsequent nodes so we do not get a port conflict
- Peer connection (Raft consensus) port default is 2380 (Just supporting a single port per node), we will increment the port for subsequent nodes so we do not get a port conflict
- Will use /tmp/etcdinv directory for the cluster - If you want the cluster to stick around use a different directory
  * If all nodes are stopped and then restarted the cluster will try to restart with this state, if the OS has not already purged this content
- Will write node logs to a file and run process in the background

```bash
# etcd bin directory
etcd_bin_dir=/home/pmcgrath/go/src/github.com/coreos/etcd/bin/

# Ensure we have a root directory for the cluster - Note we are using /tmp here, if you want the cluster to stick arounf use a different directory
mkdir -p /tmp/etcdinv

# Run node 1 
$etcd_bin_dir/etcd \
	-name node1 \
	-data-dir /tmp/ectdinv/node1 \
	-listen-peer-urls http://localhost:2380 \
	-listen-client-urls http://localhost:2379 \
	-initial-advertise-peer-urls http://localhost:2380 \
	-initial-cluster-token MyEtcdCluster \
	-initial-cluster node1=http://localhost:2380,node2=http://localhost:2381,node3=http://localhost:2382 \
	-initial-cluster-state new &> /tmp/etcdinv/node1.log &

# Run node 2 
$etcd_bin_dir/etcd \
	-name node2 \
	-data-dir /tmp/ectdinv/node2 \
	-listen-peer-urls http://localhost:2381 \
	-listen-client-urls http://localhost:2378 \
	-initial-advertise-peer-urls http://localhost:2381 \
	-initial-cluster-token MyEtcdCluster \
	-initial-cluster node1=http://localhost:2380,node2=http://localhost:2381,node3=http://localhost:2382 \
	-initial-cluster-state new &> /tmp/etcdinv/node2.log &

# Run node 3 
$etcd_bin_dir/etcd \
	-name node3 \
	-data-dir /tmp/ectdinv/node3 \
	-listen-peer-urls http://localhost:2382 \
	-listen-client-urls http://localhost:2377 \
	-initial-advertise-peer-urls http://localhost:2382 \
	-initial-cluster-token MyEtcdCluster \
	-initial-cluster node1=http://localhost:2380,node2=http://localhost:2381,node3=http://localhost:2382 \
	-initial-cluster-state new &> /tmp/etcdinv/node3.log &

# List nodes
ETCDCTL_PEERS=http://127.0.0.1:2379 $etcd_bin_dir/etcdctl member list
```
- You can see the cluster node pids using 
  * pidof etcd
  * ps aux | grep etcd


## Interacting with the cluster using etcdctl
- Will use the client port 2379 based on [this](http://www.iana.org/assignments/service-names-port-numbers)
- etcdctl defaults to 4001 at this time 
- I could have added an extra client url for 4001 when bring up the nodes, but I'm guessing 4001 will be removed at some stage

```bash
# etcd bin directory
etcd_bin_dir=/home/pmcgrath/go/src/github.com/coreos/etcd/bin/

# Using node1
# Write a key
ETCDCTL_PEERS=http://127.0.0.1:2379 $etcd_bin_dir/etcdctl set /dir1/key1 value1
# Should echo value1

# Read key
ETCDCTL_PEERS=http://127.0.0.1:2379 $etcd_bin_dir/etcdctl get /dir1/key1
# Should echo value1

# Using node3
# Read key
ETCDCTL_PEERS=http://127.0.0.1:2377 $etcd_bin_dir/etcdctl get /dir1/key1
# Should echo value1
```

## Kill one of the nodes
```bash
# etcd bin directory
etcd_bin_dir=/home/pmcgrath/go/src/github.com/coreos/etcd/bin/

# Kill node2
pidof etcd
# Should only have 3 pids
kill $(ps aux | grep 'etcd \-name node2' | cut -d ' ' -f 2)
pidof etcd
# Should only have 2 pids

# Read key using node1
ETCDCTL_PEERS=http://127.0.0.1:2379 $etcd_bin_dir/etcdctl get /dir1/key1
# Should echo value1

# Read key using node2
ETCDCTL_PEERS=http://127.0.0.1:2378 $etcd_bin_dir/etcdctl get /dir1/key1
# Should fail indicating cluster node could not available 

# Read key using node3
ETCDCTL_PEERS=http://127.0.0.1:2377 $etcd_bin_dir/etcdctl get /dir1/key1
# Should echo value1
```

## Using a proxy
```bash
# etcd bin directory
etcd_bin_dir=/home/pmcgrath/go/src/github.com/coreos/etcd/bin/

# Run a read write proxy - on 8080 
$etcd_bin_dir/etcd \
	-proxy on \
	-name proxy \
	-listen-client-urls http://localhost:8080 \
	-initial-cluster node1=http://localhost:2380,node2=http://localhost:2381,node3=http://localhost:2382 &> /tmp/etcdinv/proxy.log &

# Read existing key
ETCDCTL_PEERS=http://127.0.0.1:8080 $etcd_bin_dir/etcdctl get /dir1/key1
# Should echo value1

# Write a key
ETCDCTL_PEERS=http://127.0.0.1:8080 $etcd_bin_dir/etcdctl set /dir1/key2 value2
# Should echo value2

# Read existing key
ETCDCTL_PEERS=http://127.0.0.1:8080 $etcd_bin_dir/etcdctl get /dir1/key1
# Should echo value2
```

