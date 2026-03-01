# syntax=docker/dockerfile:1
# check=error=true
#
# Images from one Dockerfile:
#   Postgres (default):  docker build -t id:latest .
#   Standalone SQLite:   docker build --target standalone -t id:standalone .
#   Dev (Postgres):      docker build --target dev -t id:dev .

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.7
FROM docker.io/library/ruby:$RUBY_VERSION-alpine AS base

WORKDIR /rails

# Shared base: no DB client yet (added in final stages)
RUN apk add --no-cache curl jemalloc vips

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    LD_PRELOAD="/usr/lib/libjemalloc.so.2"

# ---- Postgres build ----
FROM base AS build

ENV BUNDLE_WITHOUT="development test sqlite"

RUN apk add --no-cache build-base git postgresql-dev yaml-dev pkgconfig libxml2-dev libxslt-dev vips-dev

COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY . .

RUN bundle exec bootsnap precompile -j 1 app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---- Standalone (SQLite) build ----
FROM base AS build-standalone

ENV BUNDLE_WITHOUT="development test postgres" \
    DATABASE_ADAPTER="sqlite3" \
    FIRST_RUN_DEFAULT_SQLITE="1"

RUN apk add --no-cache build-base git sqlite-dev yaml-dev pkgconfig libxml2-dev libxslt-dev vips-dev

COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY . .

RUN bundle exec bootsnap precompile -j 1 app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---- Final: Standalone SQLite image ----
FROM base AS standalone

RUN apk add --no-cache sqlite-libs

ENV BUNDLE_WITHOUT="development test postgres" \
    DATABASE_ADAPTER="sqlite3" \
    FIRST_RUN_DEFAULT_SQLITE="1"

RUN addgroup -g 1000 -S rails && \
    adduser -u 1000 -G rails -D -h /home/rails -s /bin/sh rails
USER 1000:1000

COPY --chown=rails:rails --from=build-standalone "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build-standalone /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]

# ---- Final: Dev image (Postgres, development mode) ----
FROM base AS dev

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT="sqlite"

RUN apk add --no-cache build-base git postgresql-dev yaml-dev pkgconfig libxml2-dev libxslt-dev vips-dev

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]

# ---- Final: Postgres image (default target) ----
FROM base

RUN apk add --no-cache postgresql-client

ENV BUNDLE_WITHOUT="development test sqlite"

RUN addgroup -g 1000 -S rails && \
    adduser -u 1000 -G rails -D -h /home/rails -s /bin/sh rails
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
