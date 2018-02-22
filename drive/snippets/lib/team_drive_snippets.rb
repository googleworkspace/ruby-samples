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

require 'google/apis/drive_v3'
require 'securerandom'

class TeamDriveSnippets
  def initialize(service)
    @service = service
  end

  def drive_service
    @service
  end

  def create_team_drive
    # [START createTeamDrive]
    team_drive_metadata = {
        name: 'Project Resources'
    }
    request_id = SecureRandom.uuid
    team_drive = drive_service.create_teamdrive(request_id,
                                                team_drive_metadata,
                                                fields: 'id')
    puts "Team Drive Id: #{team_drive.id}"
    # [END createTeamDrive]
    team_drive.id
  end

  def recover_team_drives(real_user)
    # [START recoverTeamDrives]
    # Find all Team Drives without an organizer and add one.
    # Note: This example does not capture all cases. Team Drives
    # that have an empty group as the sole organizer, or an
    # organizer outside the organization are not captured. A
    # more exhaustive approach would evaluate each Team Drive
    # and the associated permissions and groups to ensure an active
    # organizer is assigned.
    new_organizer_permission = {
        type: 'user',
        role: 'organizer',
        email_address: 'user@example.com'
    }
    # [START_EXCLUDE silent]
    new_organizer_permission[:email_address] = real_user
    # [END_EXCLUDE]

    team_drives = drive_service.fetch_all(items: :team_drives) do |page_token|
      drive_service.list_teamdrives(
          q: 'organizerCount = 0',
          fields: 'nextPageToken, teamDrives(id, name)',
          use_domain_admin_access: true,
          page_token: page_token)
    end

    for team_drive in team_drives
      puts "Found Team Drive without organizer: #{team_drive.name} #{team_drive.id}"
      permission = drive_service.create_permission(team_drive.id,
                                                   new_organizer_permission,
                                                   use_domain_admin_access: true,
                                                   supports_team_drives: true,
                                                   fields: 'id')
      puts "Added organizer permission: {permission.id}"
    end
    # [END recoverTeamDrives]
    return team_drives.to_a
  end
end
