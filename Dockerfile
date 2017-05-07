FROM 	ruby:latest

# Create a user that matches local user, presuming the same ids (1000)
RUN 	groupadd -g 1000 -r blogger \
	&& useradd -u 1000 -r -g blogger blogger \
	&& mkdir /blog \
	&& chown blogger:blogger /src

WORKDIR /blog
COPY 	Gemfile Gemfile
RUN 	bundle install jekyll

EXPOSE	4000

USER	blogger

CMD [ "bundler", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--watch" ]
