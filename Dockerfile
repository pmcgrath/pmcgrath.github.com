FROM 	ruby:latest

# Create a user that matches local user, presuming the same ids (1000)
RUN 	groupadd -g 1000 -r blogger \
	&& useradd -u 1000 -r -g blogger blogger \
	&& mkdir /src \
	&& chown blogger:blogger /src

WORKDIR /src
COPY 	Gemfile Gemfile
RUN 	bundle install

EXPOSE	4000

USER	blogger

ENTRYPOINT [ "ruby", "-S", "jekyll", "serve", "--host=0.0.0.0", "--watch", "--force_polling" ]
