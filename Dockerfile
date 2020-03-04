FROM ruby:2.6.5-alpine
LABEL maintainer="Murny"

# install dependencies
RUN apk add --update --no-cache \
  build-base \
  netcat-openbsd \
  nodejs \
  git \
  imagemagick \
  postgresql-dev \
  tzdata

ENV APP_ROOT /app
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

# Update bundler
RUN gem install bundler:2.1.4

# Install standard gems
COPY Gemfile* /app/
RUN bundle config --global frozen 1 && \
    bundle install -j4 --retry 3

# *NOW* we copy the codebase in
COPY . $APP_ROOT

# Add user
RUN addgroup -g 1000 -S app \
  && adduser -u 1000 -S app -G app
USER app

EXPOSE 3000
