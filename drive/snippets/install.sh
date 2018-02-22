#!/bin/bash
rvm install ruby-2.3
rvm use 2.3
rbenv install -s
gem install bundler
bundler install
