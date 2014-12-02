---
layout: post
title: Docker inspect data subsets
categories: docker
---

## Inspect the state of a docker container
You can inspect the state of a container using the following command

```bash
cid=REPLACE_THIS_WITH_THE_CONTAINER_ID_OR_NAME
docker inspect $cid
```
this returns a json document with comprehensive information on the container. This information can be manipulated using a tool like [jq](http://stedolan.github.io/jq/) on the command line. 


## Using docker inspect templates to get a subset of the data
If you use the -f argument when calling docker inspect you can use a golang [template](http://golang.org/pkg/text/template/) to control the content that gets emmited, the following are some samples


### Get the container process pid

```bash
cid=REPLACE_THIS_WITH_THE_CONTAINER_ID_OR_NAME
docker inspect -f {%raw%}'{{ .State.Pid }}'{%endraw%} $cid
> 32109
```
docker is passing the result of the object returned from a full docker inspect command to the {%raw%}'{{ .State.Pid }}'{%endraw%} go text template, it is then accessing state within the object using that first "." so we can do print anything we like 

```bash
cid=REPLACE_THIS_WITH_THE_CONTAINER_ID_OR_NAME
docker inspect -f {%raw%}'The process id is {{ .State.Pid }}'{%endraw%} $cid
> The process id is 32109
```


### Script to echo some high level info that is not included in "docker ps" command output

```bash
{%raw%}
#!/usr/bin/env bash
# Containers to run for - default is all, if none passed
containers=$@
if [[ $# -eq 0 ]]; then containers=$(docker ps -q); fi

# See http://golang.org/pkg/text/template/
template='Id: {{.Id}}
Name: {{.Name}}
Image: {{.Image}}
Pid: {{.State.Pid}}
IP: {{.NetworkSettings.IPAddress}}
Host: {{.Config.Hostname}}
EntryPoint: {{.Config.Entrypoint}}
Command: {{.Config.Cmd}}
Ports: {{range $key, $value := .Config.ExposedPorts}}{{$key}} {{end}}
Links: {{range .HostConfig.Links}}{{.}} {{end}}
Volumes: {{if .Volumes}}{{range $key, $value := .Volumes}}
  {{$key}} -> {{$value}}{{end}}{{end}}
'
docker inspect -f "$template" $containers
{%endraw%}
```

