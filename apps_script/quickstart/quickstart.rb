# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# [START apps_script_api_quickstart]
require "google/apis/script_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google Apps Script API Ruby Quickstart".freeze
CREDENTIALS_PATH = "credentials.json".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = "https://www.googleapis.com/auth/script.projects".freeze

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::ScriptV1::ScriptService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Make the API request.
request = Google::Apis::ScriptV1::CreateProjectRequest.new(
  title: "My Script"
)
resp = service.create_project request

script_id = resp.script_id
content = Google::Apis::ScriptV1::Content.new(
  files:     [
    Google::Apis::ScriptV1::File.new(
      name:   "hello",
      type:   "SERVER_JS",
      source: "function helloWorld() {\n console.log('Hello, world!');\n}"
    ),
    Google::Apis::ScriptV1::File.new(
      name:   "appsscript",
      type:   "JSON",
      source: "{\"timeZone\":\"America/New_York\",\"exceptionLogging\": \"CLOUD\"}"
    )
  ],
  script_id: script_id
)
service.update_project_content script_id, content
puts "https://script.google.com/d/#{script_id}/edit"
# [END apps_script_api_quickstart]
