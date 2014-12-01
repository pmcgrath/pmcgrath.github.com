---
layout: post
title: Git on windows
categories: git windows
---


## Environment
Work development environment is Windows, which means I interact with git using powershell and [msysgit](http://msysgit.github.com/)  
Can use [posh-git](https://github.com/dahlbyk/posh-git)


## Powershell profile
[pmcgrath profile](https://github.com/pmcgrath/powershellprofile)  
[posh-git](https://github.com/dahlbyk/posh-git) is more suitable for most


## Windows remote bare repositories
This is based on [kozmic's content](http://kozmic.pl/2011/08/20/simple-guide-to-running-git-server-on-windows-in-local-network-kind-of/)  
Created a shared directory on a file server, giving domain users modify permissions  
To create the bare repository on the file server run - git init --bare //fileserver/scm/myrepo.git  
To clone this repository on a workstation run - git clone //fileserver/scm/myrepo.git


## SSH
[Generating ssh keys](https://help.github.com/articles/generating-ssh-keys) on github  
[Working with ssh key passphrases](https://help.github.com/articles/working-with-ssh-key-passphrases) on github  
[git windows setup](https://help.github.com/articles/set-up-git/#platform-windows/) on github  
[posh git](https://github.com/dahlbyk/posh-git) powershell module (GitUtils.ps1 file)

Generate key using ssh-keygen

```powershell
ssh-keygen -t rsa
```
Ensure ssh-agent is on path and not already running  

```powershell
ssh-agent | ? { $_ -match '(?<key>[^=]+)=(?<value>[^;]+);' | % { $key = $matches['key']; $value =$matches['value']; set-item env:$key $value; } }
if (test-path ~/.ssh/id_rsa) { ssh-add ~/.ssh/id_rsa; }
# To verify above can use the following
ssh-add -l # to see added identities
ssh -v git@github.com # to test
```


## Hooks
See [hooks](/git-hooks)


## Powershell script to watch file usage when interacting with git
Tried to run Tim Berglund's bash script, but since [msysgit](http://msysgit.github.com/) currently comes with a very old version of bash it did not work, so just used powershell equivalent  
Obviously you can only really watch a small repo, if you want to be able to see all the files  
Probably a good idea to remove all the sample hooks in the .git/hooks directory  
Open two terminals side by side, running the below script from within the .git directory of the repository you want to observe  

```powershell
for(;;) { clear; tree /F; sleep 1; }
```


## Good presentations
- [Jessica Kerr](http://vimeo.com/46010208) explains git using a whiteboard
- [Tim Berglund](http://vimeo.com/49478285) explains git internals in short video, really good content
- [Brandon Keepers](http://vimeo.com/44458223) explains git as a nosql database


## git libraries
- grit    # Wrapper around shell calls
- libgit2 # c code with bindings for a lot of languages

