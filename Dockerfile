FROM ruby:2.2.5-slim

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y \
    nodejs curl npm \
    git-core \
    build-essential \
    patch

RUN apt-get install -y \
    libpq-dev \
    postgresql-client \
    libsqlite3-dev \
    sqlite3 \
    libxslt1-dev \
    liblzma-dev

RUN apt-get install -y \
    imagemagick \
    libfreetype6 \
    libfontconfig

RUN echo 'gem: --no-rdoc --no-ri' >> $HOME/.gemrc

ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install --jobs 2 --verbose

ENV BUNDLE_PATH /cache

ADD . $APP_HOME
