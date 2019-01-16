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
def truncated(array, limit=2)
  contents = array[0...limit].join(", ")
  more = array.length <= limit ? "" : ", ..."
  return "[#{contents}#{more}]"
end

# Returns the name of a set property in an object, or else "unknown".
def getOneOf(obj)
  for var in obj.instance_variables
    return var[/^@?(.*)/,1]
  end
  return "unknown"
end

# Returns a time associated with an activity.
def getTimeInfo(activity)
  if not activity.timestamp.nil?
    return "   " + activity.timestamp
  elsif not activity.time_range.nil?
    return "..." + activity.time_range.end_time
  end
  return "unknown"
end

# Returns the type of action.
def getActionInfo(actionDetail)
  return getOneOf(actionDetail)
end

# Returns user information, or the type of user if not a known user.
def getUserInfo(user)
  if not user.known_user.nil?
    knownUser = user.known_user
    isMe = knownUser.is_current_user || false
    return isMe ? "people/me" : knownUser.person_name
  end
  return getOneOf(user)
end

# Returns actor information, or the type of actor if not a user.
def getActorInfo(actor)
  if not actor.user.nil?
    return getUserInfo(actor.user)
  end
  return getOneOf(actor)
end

# Returns the type of a target and an associated title.
def getTargetInfo(target)
  if not target.drive_item.nil?
    title = target.drive_item.title || "unknown"
    return %(driveItem:"#{title}")
  elsif not target.team_drive.nil?
    title = target.team_drive.title || "unknown"
    return %(teamDrive:"#{title}")
  elsif not target.file_comment.nil?
    parent = target.file_comment.parent
    title = parent.nil? ? "unknown" : (parent.title || "unknown")
    return %(fileComment:"#{title}")
  end
  return "#{getOneOf(target)}:unknown"
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
  time = getTimeInfo(activity)
  action = getOneOf(activity.primary_action_detail)
  actors = activity.actors.map { |actor| getActorInfo(actor) }
  targets = activity.targets.map { |target| getTargetInfo(target) }
  puts "#{time}: #{truncated(actors)}, #{action}, #{truncated(targets)}"
end
# [END drive_activity_v2_quickstart]
