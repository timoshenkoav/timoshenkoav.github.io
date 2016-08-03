---
layout: post
title:  "Use docker to deploy rails app"
date:   2016-07-18 13:40:00
tags: rails docker
meta_description: Use Docker to deploy rails app
---


1. Download and install docker
https://docs.docker.com/docker-for-mac/

2. Add Docker bash completions
```
cd /usr/local/etc/bash_completion.d
ln -s /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion
ln -s /Applications/Docker.app/Contents/Resources/etc/docker-machine.bash-completion
ln -s /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion
```