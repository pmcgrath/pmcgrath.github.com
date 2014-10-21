---
layout: post
title: Create content using github pages
---
  
## Creating the github pages repository
Create a public repository on github and name as pmcgrath.github.com where pmcgrath is the github account name  
Clone the project locally using the appropriate github url  
i.e. git clone git@github.com:pmcgrath/pmcgrath.github.com.git  
  

## Set up repository directory content skeleton
```
cd pmcgrath.github.com.git
mkdir assets
mkdir assets\css
mkdir assets\image 
mkdir \_layouts
mkdir \_posts
```


## Basic files
Create the following files
- \_config.yml
- index.html
- \_layouts\default.html


## Notes
- Can use [dillinger](http://dillinger.io/) toedit markdown in the browser
- No tabs allowed in the \_config.yml file as indicated @ https://github.com/mojombo/jekyll/wiki/Configuration
- Make sure files comming from windows are ansi to make life easier, if utf-8 encoding files need to make sure there is no BOM as indicated @ https://github.com/mojombo/jekyll/wiki/YAML-Front-Matter or else the build will fail and you will not see updates after a push
- Markdown see http://daringfireball.net/projects/markdown/
  * Need 2 trailing spaces for new lines
  * For code we need to use backticks at the start and end of each line of text
  * Need to escape some chars such as \_ see http://daringfireball.net/projects/markdown/syntax#backslash
  * To include script i had to use an opening and closing tag on different lines, not sure why but could not create gist links without doing so
- Using amazon s3 instead http://vvv.tobiassjosten.net/development/jekyll-blog-on-amazon-s3-and-cloudfront/
