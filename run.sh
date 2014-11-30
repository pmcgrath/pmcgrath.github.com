#!/usr/bin/env bash
image_name=github-pages
container_name=github-pages

which docker > /dev/null
if [ $? != 0 ]; then
	echo Docker is a requirement
	exit 1
fi

id | grep '(docker)' > /dev/null
if [ $? != 0 ]; then
	echo You are not a member of the local docker group, you must run this script with elevated privileges i.e sudo $0
	exit 2 
fi

docker images $image_name | grep $image_name > /dev/null
if [ $? != 0 ]; then
	echo You have not build the required docker image, can use the following
	echo docker build -t $image_name .
	exit 3 
fi

# Will run in interactive mode, could have used -d but this is usually short lived
docker run -it --name $container_name --rm -v $(pwd):/src -p 4000:4000 $image_name
