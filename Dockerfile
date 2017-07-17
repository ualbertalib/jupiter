FROM ruby:2.3.4
MAINTAINER Murny

# Need to add jessie-backports repo so we can get FFMPEG, doesn't come with jessie debian by default
# RUN echo 'deb http://ftp.debian.org/debian jessie-backports main'  >> /etc/apt/sources.list

RUN apt-get update -qq \
    && apt-get install -y build-essential \
                          mysql-client \
                          nodejs \
                          # npm \
                          # nodejs-legacy \
                          # libreoffice \
                          # imagemagick \
                          # ghostscript \
                          # unzip \
                          # ffmpeg \
    && rm -rf /var/lib/apt/lists/*


# install fits
# RUN mkdir -p /usr/local/fits \
#     && cd /usr/local/fits \
#     && wget http://projects.iq.harvard.edu/files/fits/files/fits-1.0.6.zip \
#     && unzip fits-1.0.6.zip \
#     && rm  fits-1.0.6.zip \
#     && chmod a+x /usr/local/fits/fits-1.0.6/fits.sh \
#     && ln -s /usr/local/fits/fits-1.0.6/fits.sh /usr/bin/fits

# install phantomjs for capybara as we are using poltergeist
# RUN npm install -g phantomjs-prebuilt

RUN mkdir -p /app
WORKDIR /app

# Preinstall gems in an earlier layer so we don't reinstall every time any file changes.
COPY Gemfile /app
COPY Gemfile.lock /app
RUN bundle install

# *NOW* we copy the codebase in
ADD . /app

EXPOSE 3000
