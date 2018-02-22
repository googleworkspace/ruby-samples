#!/bin/bash
set -e

export GOOGLE_APPLICATION_CREDENTIALS=../../application_credentials.json
bundle exec rspec
