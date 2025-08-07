#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install --jobs 4 --retry 3 --without development test

# Create and migrate primary database
bundle exec rails db:create db:migrate

# Run solid_queue migrations
bundle exec rails solid_queue:install:migrations
bundle exec rails db:migrate RAILS_ENV=production

# Run solid_cache migrations
bundle exec rails solid_cache:install:migrations
bundle exec rails db:migrate RAILS_ENV=production
