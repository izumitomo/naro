# syntax = docker/dockerfile:1

FROM node:20.10-slim as node

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
FROM ruby:3.2.1 

# Rails app lives here
WORKDIR /myapp

# Set production environment
ENV BUNDLER_VERSION="2.4.21" \
    BUNDLE_PATH="/myapp/vendor/bundle" \
    RUBYGEMS_VERSION="3.4.21"

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips pkg-config libpq-dev
    
# postgresql-clientだけ別サーバーから取得する
RUN apt-get update && \
apt-get install -y wget gnupg2 lsb-release && \
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
apt-get update && \
apt-get install -y postgresql-client-15

# Install application gems
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock

RUN echo 'gem: --no-document' >> ~/.gemrc && \
    gem update --system ${RUBYGEMS_VERSION} && \
    gem install bundler:${BUNDLER_VERSION} && \
    # bundle config --global build.nokogiri --use-system-libraries && \
    bundle install
    # rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# コンテナ起動時に実行させるスクリプトを追加
# COPY entrypoint.sh /usr/bin/
# RUN chmod +x /usr/bin/entrypoint.sh
# ENTRYPOINT ["entrypoint.sh"]
# EXPOSE 4000

# CMD:コンテナ実行時、デフォルトで実行したいコマンド
# Rails サーバ起動
# CMD ["rails", "server", "-b", "0.0.0.0"]

# Precompile bootsnap code for faster boot times
# RUN bundle exec bootsnap precompile app/ lib/


# Final stage for app image
# FROM base

# Install packages needed for deployment
# RUN apt-get update -qq && \
#     apt-get install --no-install-recommends -y curl libsqlite3-0 libvips && \
#     rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
# COPY --from=build /usr/local/bundle /usr/local/bundle
# COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
# RUN useradd rails --create-home --shell /bin/bash && \
#     chown -R rails:rails db log storage tmp
# USER rails:rails

# Entrypoint prepares the database.
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
# EXPOSE 4000
# CMD ["./bin/rails", "server"]
