---
layout: post
title: Raw content in Jekyll markdown
categories: jekyll markdown
---

This is an issue when including golang template and angular content in markdown, both of which use {%raw%}{{ and }}{%endraw%}  
You need to surround the content with the {{ "{%raw"}}%} and {{ "{%endraw"}}%} tags  
 
i.e. for a golang program using a text template

```go
{%raw%}
package main

import (
	"os"
	"text/template"
)

func main() {
	ted := struct {
		Name string
	}{"ted"}

	tmpl, err := template.New("test").Parse("His name is {{.Name}}\n")
	if err != nil {
		panic(err)
	}
	err = tmpl.Execute(os.Stdout, ted)
	if err != nil {
		panic(err)
	}
}
{%endraw%}
``` 

you can 

- Surround the entire content with {{ "{%raw"}}%} and {{ "{%endraw"}}%} tags, less work 
- Surround only the piece that causes the issue with {{ "{%raw"}}%} and {{ "{%endraw"}}%} tags

### Surround the entire content with {{ "{%raw"}}%} and {{ "{%endraw"}}%} tags
```go
{%raw%}{%raw%}{%endraw%}{%raw%}
package main

import (
	"os"
	"text/template"
)

func main() {
	ted := struct {
		Name string
	}{"ted"}

	tmpl, err := template.New("test").Parse("His name is {{.Name}}\n")
	if err != nil {
		panic(err)
	}
	err = tmpl.Execute(os.Stdout, ted)
	if err != nil {
		panic(err)
	}
}
{%endraw%}{%raw%}{%{%endraw%}endraw%}
``` 
### Surround only the piece that causes the issue with {{ "{%raw"}}%} and {{ "{%endraw"}}%} tags
```go
package main

import (
	"os"
	"text/template"
)

func main() {
	ted := struct {
		Name string
	}{"ted"}

	tmpl, err := template.New("test").Parse("His name is {%raw%}{%raw%}{%endraw%}{%raw%}{{.Name}}{%endraw%}{%raw%}{%{%endraw%}endraw%}\n")
	if err != nil {
		panic(err)
	}
	err = tmpl.Execute(os.Stdout, ted)
	if err != nil {
		panic(err)
	}
}
``` 
