#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install --jobs 4 --retry 3

# Run database migrations
bundle exec rails db:migrate
