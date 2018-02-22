#!/bin/bash
sudo chown -R `whoami`:admin /usr/local/bin # permission error
if ! type "rvm" > /dev/null 2>&1; then
  echo 'Please install RVM:'
  echo 'curl -sSL https://get.rvm.io | bash -s stable --ruby'
  exit 1
fi

rvm install ruby-2.3
rvm use 2.3
gem install bundler

bundle install
