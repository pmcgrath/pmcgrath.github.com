---
layout: post
title: How to get golang package import list
categories: golang
---


This [page](https://golang.org/cmd/go/#hdr-List_packages) contains the data that is available to the go list command, we use golang templates to extract subsets of this data below
 

## Get imports for the current directory package
```bash
go list -f '{{range $imp := .Imports}}{{printf "%s\n" $imp}}{{end}}' | sort
```
This lists all the imports for the current package


## Get list of non standard dependencies
```bash
go list -f '{{range $dep := .Deps}}{{printf "%s\n" $dep}}{{end}}' | xargs go list -f '{{if not .Standard}}{{.ImportPath}}{{end}}'
```
This lists all the non standard dependencies for the current package

