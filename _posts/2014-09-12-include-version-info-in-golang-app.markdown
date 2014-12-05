---
layout: post
title: Include version information in a golang application
categories: golang 
---

## Purpose
Include some version information in a golang application when building it  
See [docker](https://github.com/docker/docker), [drone](https://github.com/drone/drone) etc. where you can run a version command and see this information


## Background
- See golang [build](http://golang.org/cmd/go/#hdr-Compile_packages_and_dependencies) command's -ldflags argument
- More detailed information is [here](http://golang.org/cmd/ld/) see the -X option
- So we can pass name value pairs when building or installing an application
- If we use keys that are of the format importpath.name we will be able to set string vars when building the package for the application


## golang app
Save this in /tmp/app/main.go

```go
package main

import (
	"fmt"
)

var (
	commit  string
	builtAt string
	builtBy string
	builtOn string
)

func main() {
	fmt.Print("Version info :: ")
	fmt.Printf("commit: %s ", commit)
	fmt.Printf("built @ %s by %s on %s\n", builtAt, builtBy, builtOn)

	// Do work
}
```

## Build\install the application

```bash
commit=`git rev-parse --short HEAD`
built_at=`date +%FT%T%z`
built_by=${USER}
built_on=`hostname`
 
go build -ldflags "-X main.commit ${commit} -X main.builtAt '${built_at}' -X main.builtBy ${built_by} -X main.builtOn ${built_on}"
```
- So we just pass each of our key values in the form "-X key value" in the -ldflags argument
- The -ldflags argument can be used for go build, go run and go install commands
- Any values that include white space will need to surround with extra quotes, see buildAt above
- The keys match the importpath.name format
- The passed values will override the initial values in the source


## Run the application
```bash
./app
>Version info :: commit: de31196 built @ 2014-12-05T18:01:31+0000 by pmcgrath on Inspiron-7520
>
```


## Can set other package values
To see the list of options run "go tool nm app"

