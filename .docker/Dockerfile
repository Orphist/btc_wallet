# Use a recent and stable Ruby image
FROM ruby:3.1.0-bullseye

ENV APP_PATH /app
ENV HOME ${APP_PATH}

WORKDIR ${APP_PATH}

COPY Gemfile .

RUN apt-get update \
    && apt-get -y install \
    procps \
    curl \
    bash \
    ruby-dev \
    libffi-dev \
    && apt-get clean \

USER nobody

RUN gem install bundler:2.5.23 \
  && bundle config set clean 'true' \
  && bundle config set path ${GEM_HOME} \
  && bundle config set without 'development' \
  && bundle install --jobs $(nproc)

COPY . .
