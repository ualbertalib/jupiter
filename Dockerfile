FROM ruby:2.5.0-alpine
LABEL maintainer="Murny"

# install dependencies
RUN apk add --update \
  build-base \
  netcat-openbsd \
  nodejs \
  git \
  imagemagick \
  postgresql-dev \
  tzdata \
  && rm -rf /var/cache/apk/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

ENV APP_ROOT /app
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT

COPY Gemfile Gemfile.lock $APP_ROOT/
RUN bundle install --without uat staging production --jobs=3 --retry=3

# *NOW* we copy the codebase in
COPY . $APP_ROOT

EXPOSE 3000
