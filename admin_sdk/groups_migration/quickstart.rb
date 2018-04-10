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
# [START admin_sdk_groups_migration_quickstart]
require 'google/apis/groupsmigration_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Groups Migration API Ruby Quickstart'.freeze
CLIENT_SECRETS_PATH = 'client_secrets.json'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::GroupsmigrationV1::AUTH_APPS_GROUPS_MIGRATION

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         'resulting code after authorization:\n' + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::GroupsmigrationV1::GroupsMigrationService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

puts 'Warning: A test email will be inserted into the group entered below.'
puts 'Enter the email address of a Google Group in your domain: '
group_id = gets.strip

# Format an RFC822 message
now = Time.now
message_id = "#{now.to_f}-#{group_id}"
message_date = now.strftime '%a, %d %b %Y %T %z'
message = <<~MESSAGE
  Message-ID: <#{message_id}>
  Date: #{message_date}
  To: #{group_id}
  From: "Alice Smith" <alice@example.com>
  Subject: Groups Migration API Test

  This is a test.
MESSAGE

# Insert a test email into the group.
response = service.insert_archive(group_id,
                                  upload_source: StringIO.new(message),
                                  content_type: 'message/rfc822')
puts "Result: #{response.response_code}"
# [END admin_sdk_groups_migration_quickstart]
