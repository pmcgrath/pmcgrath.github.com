---
layout: post
title: Getting started with Clojure
categories: clojure
---

## Purpose
These are just a couple of pointers for getting started with Clojure, as I have been asked this question and I know when I started I would have appreciated the same content.
I am new enough to Clojure so this content is based on my current understanding.
This post will explain how to get an Ubuntu linux JVM environment up and running so we can explore Clojure. 
You should be able to setup an environment on other OSes by using the equivalent OS commands.


## What is Clojure
[Clojure](http://en.wikipedia.org/wiki/Clojure) is a dialect of the Lisp programming language. It is a dynamic functional language that runs in a hosted environment. 
The most popular hosted environment is the JVM. There are versions which can be hosted on other environments, see [CLR](https://github.com/clojure/clojure-clr) and [JavaScript](https://github.com/clojure/clojurescript). 


## Docker
You can use the offical docker [image](https://registry.hub.docker.com/_/clojure/) which will have the pre-requisites already installed.

## Pre-requisites
This section will describe setting up your local machine, if you are using the docker image this does not apply.

### JVM
JVM - Ensure we have a JVM, so we have a hosted environment for Clojure. Clojure currently requires Java 1.6 or greater.
You can check if you already have Java and which JVM using the following

```bash
# Do I already have Java ?
which java

# Which Java to I already have ?
dpkg -S $(readlink -f $(which java))
```

If you need to install Java, there are many [JVMs](http://en.wikipedia.org/wiki/List_of_Java_virtual_machines), I will use OpenJDK 7

```bash
# Ensure our package lists are up to date
apt-get update

# Install OpenJDK 7
apt-get install -y openjdk-7-jdk
```

## Minimal Clojure usage
Since we already have a JVM, we just need the Clojure JAR itself. Clojure is just another Java package.
### Get Clojure JAR extracting to a temp directory

```bash
# Make temp directory in /tmp and change to this directory - This directory will be deleted by the OS in time
dir_name=$(mktemp -d)
cd $dir_name

# Download jar - its in a zip file so we need to extract (Requires unzip utility)
wget http://repo1.maven.org/maven2/org/clojure/clojure/1.6.0/clojure-1.6.0.zip
unzip clojure-1.6.0.zip 

# Copy JAR to this directory
cp clojure-1.6.0/clojure-1.6.0.jar .
```

### Start a REPL
A REPL is a read eval print loop that allows interactive programming. Ruby has irb, erlang has erl etc.

```bash
# Run java with clojure-1.6.0.jar in the classpath and execute clojure.main entry point
java -cp clojure-1.6.0.jar clojure.main
```
You can now execute Clojure expressions such as (+ 1 2) which will be evaluated and the result of the expression will be printed.
Ctrl-d to exit the REPL.


### Run a program
You can run a program - silly example but just to illustrate

```bash
# Create app.clj file which just prints Hello world
echo '(println "Hello world")' > app.clj

# Run program
java -cp clojure-1.6.0.jar clojure.main app.clj
```


## leiningen
[leiningen](http://leiningen.org/) seems to be the most popular way to manage Clojure code.
The [tutorial](https://github.com/technomancy/leiningen/blob/stable/doc/TUTORIAL.md) details the functions and extensions that this tool provides.
Some of the features you can use it for

- Installing Clojure (Let it manage this rather than using the minimal Clojure usage described above)
- Creating projects - Like scaffolding in other enviornments (Ruby on Rails, ASP.NET)
- Directory layout standardisation
- Managing dependencies (Like Bundler, go get, nuget etc)
- Running a REPL
- Running the application
- Running tests
- Builds (Building a single application Uberjar)
- Plugins (Like managing ClojureScript builds)

### Installation
See the projet [site](http://leiningen.org/)

```bash
# Create bin directory if it does not already exist
[ -d ~/bin ] || mkdir ~/bin

# Get leiningen script and make executable
cd ~/bin
wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod +x ~/bin/lein

# May need to exit and reload shell if bin directory did not already exist so it will be on the path
# See ~/.profile which should add ~/bin to path if it exists

# Run lein - Will download and self-install the leiningen package
lein 
```


## Basic hello world application
Create new app (With a main function so it can be run from the command line), this uses the app template to create a main entry point function.

```bash
# Create new app
lein new app hello
cd hello

# List all files excluding target directory content
find -type f -not -path './target/*' | sort
> ./doc/intro.md
> ./.gitignore
> ./.hgignore
> ./LICENSE
> ./project.clj
> ./README.md
> ./src/hello/core.clj
> ./test/hello/core_test.clj

# Run app 
lein run
```

The important files are

- src/hello/core.clj - This file contains code, and the entry point function main
- test/hello/core.clj - This file contains a test, the test will fail until corrected
- project.clj - This file contains project attributes, dependencies, leiningen plugins etc.


## REPL
You can start a REPL using

```bash
lein repl
```
- This will start a REPL and switch to the "hello.core" namespace.
- All of the dependencies in the project.clj will be available, they will all be included in the classpath and can be required.
- You can execute functions that have been defined.
- You can run tests that have been defined.

To run already defined functions within the same REPL

```clojure
; Execute the -main function which is defined in the src/hello/core.clj file
(-main)
```

To run the test function that was created (This is a sample that is set to fail) within the same REPL

```clojure
; Require namespaces
(require 'clojure.test)
(require 'hello.core-test)

; Execute the run-tests function for the test namespace
(clojure.test/run-tests 'hello.core-test)
```

You can also see the documentation and source for functions within the repl as follows

```clojure
; Get the documentation for the map function
(doc map)

; Get the source for the map function
(source map)
```


## Basic hello world web app
Create new web app, this will create a library app that does not have a main entry function

```bash
# Create new app
lein new helloweb
cd helloweb
```

Alter the project.clj as follows

```clojure
(defproject helloweb "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [ring/ring-core "1.3.2"]]
  :plugins [[lein-ring "0.8.13"]]
  :ring {:handler helloweb.core/handler})
```
- We have added an extra dependency [ring-core](https://github.com/ring-clojure/ring) v1.3.2
- We have added an extra leiningen plugin lein-ring v0.8.13
- We have added an extra ring attribute indicating the handler to use - this will be the entry point for the app.


Alter the src/helloweb/core.clj as follows

```clojure
(ns helloweb.core)

; Single function that responds to all request as we have no routing configured
(defn handler 
  [request]
  {:status 200
   :headers {"Content-Type" "text/html"}
   :body "Hello World"})
```

- We have removed the default function that gets added when lein new was invoked.
- We have added a new function named handler and we take a single request parameter and return a map that ring expects (status, headers and body).

Run the app with the following, note we are using the ring plugin

```bash
lein ring server-headless
```

This will open your default browser on localhost port 3000, serving the content.

To see the http content open another terminal and run 

```bash
curl -v -w '\n' http://localhost:3000
```

This is a very basic web app and there are much better tools for creating web apps\api applications.


# Editors
I am currently using vim with no plugins but there are vim plugins for clojure and most people seem to be using emacs.


# Running tests
You can run tests that are defined in the test directory using the following

```bash
lein test
```
Since we didn't change the test included when we created the app this will fail.


## Good online resources for getting started
- [CLOJURE for the BRAVE and TRUE](http://www.braveclojure.com/) - Very good sieries of blog entries that you can also buy as a book
- [Clojure from the ground up](https://aphyr.com/tags/Clojure-from-the-ground-up) - Very good series of blog entries
- [Mathias's](https://github.com/matthiasn/Clojure-Resources) list of learning resources
- [Styleguide](https://github.com/bbatsov/clojure-style-guide) which helps with understanding code layout
