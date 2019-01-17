# Copyright 2019 Google LLC
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
# [START drive_activity_v2_quickstart]
require 'google/apis/driveactivity_v2'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Drive Activity API Ruby Quickstart'.freeze
CREDENTIALS_PATH = 'credentials.json'.freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::DriveactivityV2::AUTH_DRIVE_ACTIVITY_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Returns a string representation of the first elements in a list.
def truncated(array, limit = 2)
  contents = array[0...limit].join(', ')
  more = array.length <= limit ? '' : ', ...'
  "[#{contents}#{more}]"
end

# Returns the name of a set property in an object, or else "unknown".
def get_one_of(obj)
  obj.instance_variables.each do |var|
    return var[/^@?(.*)/, 1]
  end
  'unknown'
end

# Returns a time associated with an activity.
def get_time_info(activity)
  return activity.timestamp unless activity.timestamp.nil?
  return activity.time_range.end_time unless activity.time_range.nil?

  'unknown'
end

# Returns the type of action.
def get_action_info(action_detail)
  get_one_of(action_detail)
end

# Returns user information, or the type of user if not a known user.
def get_user_info(user)
  unless user.known_user.nil?
    known_user = user.known_user
    is_me = known_user.is_current_user || false
    return is_me ? 'people/me' : known_user.person_name
  end
  get_one_of(user)
end

# Returns actor information, or the type of actor if not a user.
def get_actor_info(actor)
  return get_user_info(actor.user) unless actor.user.nil?

  get_one_of(actor)
end

# Returns the type of a target and an associated title.
def get_target_info(target)
  if !target.drive_item.nil?
    title = target.drive_item.title || 'unknown'
    return %(driveItem:"#{title}")
  elsif !target.team_drive.nil?
    title = target.team_drive.title || 'unknown'
    return %(teamDrive:"#{title}")
  elsif !target.file_comment.nil?
    parent = target.file_comment.parent
    title = parent.nil? ? 'unknown' : (parent.title || 'unknown')
    return %(fileComment:"#{title}")
  end
  "#{get_one_of(target)}:unknown"
end

# Initialize the API
service = Google::Apis::DriveactivityV2::DriveActivityService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize
request = Google::Apis::DriveactivityV2::QueryDriveActivityRequest.new(page_size: 10)
response = service.query_drive_activity(request)
puts 'Recent activity:'
puts 'No activity.' if response.activities.empty?
response.activities.each do |activity|
  time = get_time_info(activity)
  action = get_action_info(activity.primary_action_detail)
  actors = activity.actors.map { |actor| get_actor_info(actor) }
  targets = activity.targets.map { |target| get_target_info(target) }
  puts "#{time}: #{truncated(actors)}, #{action}, #{truncated(targets)}"
end
# [END drive_activity_v2_quickstart]
