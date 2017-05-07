IMAGE_NAME = pmcgrath/github-pages:2.0


docker-build-image:
	docker image build --tag ${IMAGE_NAME} .


docker-run:
	docker container run -ti --rm --name blog --volume $$(pwd):/blog -p 4000:4000 ${IMAGE_NAME} 
