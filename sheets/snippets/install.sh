#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

command -v rbenv >/dev/null 2>&1 || { echo >&2 "rbenv required, aborting."; exit 1; }
command -v ruby-build >/dev/null 2>&1 || { echo >&2 "ruby-build required, aborting."; exit 1; }
rbenv install -s
gem install bundler
bundler install
