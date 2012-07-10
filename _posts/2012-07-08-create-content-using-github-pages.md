---
layout: post
title: Create content using github pages
---

## Creating the github pages repository
Create a public repository on github and name as pmcgrath.github.com where pmcgrath is the github account name

Clone the project locally using the appropriate github url (ssh or https)

i.e. git clone https://github.com/pmcgrath/pmcgrath.github.com.git

## Set up repository directory content skeleton
git clone git@github.com:pmcgrath/pmcgrath.github.com.git

cd pmcgrath.github.com.git

mkdir assets

mkdir assets\css

mkdir assets\images

mkdir _layouts

mkdir _posts

## Basic content
Create the following fields ensuring they do not include a BOM if utf8
* config.yml
* index.html
* layouts\default.html