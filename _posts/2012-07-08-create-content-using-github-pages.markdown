---
layout: post
title: Create content using github pages
categories: jekyll github markdown docker
---

## EDIT
This content has been completely altered since this initial posting, this is current as of Dec 2016


## Purpose
Create a website with static content using markdown


## Required software
See [github_pages](https://pages.github.com/), you will need the following

- [Ruby](https://www.ruby-lang.org/en/)
- [Jekyll](https://help.github.com/articles/using-jekyll-with-pages/) and other gems
- [Redcarpet](https://github.com/vmg/redcarpet)
- [therubyracer](https://github.com/jekyll/jekyll/issues/2327) javascript environment gem

Rather than having this software on my local machine I will use a [docker](https://www.docker.com/) container


## Workflow
- Create a github repository named pmcgrath.github.com (pmcgrath.github.io for newer accounts)
- Clone github repository
- Initialise jekyll content, see below
- Run docker container serving jekyll content
- Run the following in a loop until you are happy with the content
  * Edit content locally
  * View content in browser @ http://localhost:4000/
- Push content to github


## Docker usage
- I have a docker image so that I can create and edit content locally and view it before I push to github
- I do not need any of the required software on my local machine
- To build an image you will need the following files
  * [Dockerfile](https://raw.githubusercontent.com/pmcgrath/pmcgrath.github.com/master/Dockerfile)
  * [Gemfile](https://raw.githubusercontent.com/pmcgrath/pmcgrath.github.com/master/Gemfile)
  * [docker ignore](https://raw.githubusercontent.com/pmcgrath/pmcgrath.github.com/master/.dockerignore)
- To build the image run the following bash command (Will need sudo prefix if user is not in the docker group)

```bash
docker image build -t pmcgrath/github-pages:1.0 .
```
- To Run an instance of the docker image which watches for changes while editing, run an instance using

```bash
docker container run --rm -it --name github-pages -p 4000:4000 --volume $(pwd):/src pmcgrath/github-pages:1.0
```


## Initialise jekyll content
- Use the following bash command within the empty cloned repository to create the initial content

```bash
docker container run --rm -it --name github-pages --rm -v $(pwd):/src pmcgrath/github-pages:1.0 ruby -S jekyll new .
```
- Edit the settings in the _config.yml file, changing the values appropriately
- Use [redcarpet](http://stackoverflow.com/questions/13464590/github-flavored-markdown-and-pygments-highlighting-in-jekyll$) markdown engine so we can use fenced code blocks, add the following to the _config.yml file
  * markdown: redcarpet             # So we can use fences code blocks
- Use permalinks for the links, so we just use the title for the urls, add the following to the _config.yml file
  * permalink: /:title              # So title alone is used for the link


## Create blog posts
- Add a file to the _posts directory, you can copy the default post created when the jekyll content was initialised


## Jekyll notes
- Converts mardown content to static html content
- Places the static version in the _site directory, can do so manually using the build command
- Can serve content by running a web server listening on port 4000
- Can be instructed to watch for content changes, which will result in re-generating the static content
- Changes to the _config.yml will require restarting the container


## Notes
- Using [Jekyll](http://jekyllrb.com/) to generate the content
- [Markdown](http://daringfireball.net/projects/markdown/)
- Using [Github flavoured markdown](https://help.github.com/articles/github-flavored-markdown/)
- Can use [dillinger](http://dillinger.io/) to edit markdown in the browser
- Can do so with Amazon S3 also, see [here](http://vvv.tobiassjosten.net/development/jekyll-blog-on-amazon-s3-and-cloudfront/)
- [hugo](http://gohugo.io/) golang alternative
