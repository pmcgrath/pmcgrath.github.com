---
layout: post
title: Managing golang dependencies
categories: golang 
---

## Purpose
- This is how I currently manage my golang dependencies (vendoring)
- I currently use the [godep](https://github.com/tools/godep) tool
- This post is just to remind me of a couple of things that are not pointed out in the godep documentation


## Background
- See the offiicial golang [faq](http://golang.org/doc/faq#get_version) for their view on dependency management
- See package management tool choices [here](https://github.com/golang/go/wiki/PackageManagementTools)
- To understand how godep works read the [readme](https://github.com/tools/godep), this content is just some extra stuff I keep having to remember


## Commit dependencies
- godep now indicates the Godeps sub directory should be commited 
- There is a .gitignore file with entries for the bin and pkg directories within the workspace directory, so only the source is commited


## Relying on specific dependency versions
- When you first take the dependencies using the "godep save" command it records the current versions of the dependencies
- If you need to use a specific branch or version of one of the dependencies you should check that out before running the "godep save" command
- If you have already taken the dependencies using the "godep save" command, you can always checkout a specific version of a dependency and then run "godep update" for the dependency


## Updating specific dependencies
- As indicated in the godep readme, run the "godep update" command


## Building\Installing\Running
- Use godep so you are in fact using the vendored versions rather then the cloned versions

