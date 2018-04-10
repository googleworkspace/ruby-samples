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
# [START admin_sdk_reseller_quickstart]
require 'google/apis/admin_reports_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Reseller API Ruby Quickstart'.freeze
CLIENT_SECRETS_PATH = 'client_secrets.json'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::ResellerV1::AUTH_APPS_ORDER

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
service = Google::Apis::ResellerV1::ResellerService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize
# Print the first 10 subscriptions you manage.
response = service.list_subscriptions(max_results: 10)

puts "Subscriptions:"
puts "No subscriptions found" if response.subscriptions.empty?
response.subscriptions.each do |subscription|
  puts "- #{subscription.customer_id} (#{subscription.sku_id}, #{subscription.plan.plan_name})"
end
# [END admin_sdk_reseller_quickstart]
