#!/bin/bash
command -v rbenv >/dev/null 2>&1 || { echo >&2 "rbenv required, aborting."; exit 1; }
command -v ruby-build >/dev/null 2>&1 || { echo >&2 "ruby-build required, aborting."; exit 1; }
rbenv install -s
gem install bundler
bundler install
