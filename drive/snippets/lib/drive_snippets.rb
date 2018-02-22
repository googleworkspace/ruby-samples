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

class DriveSnippets
  def initialize(service)
    @service = service
  end

  def drive_service
    @service
  end

  def upload_basic
    # [START uploadBasic]
    file_metadata = {
        name: 'photo.jpg'
    }
    file = drive_service.create_file(file_metadata,
                                     fields: 'id',
                                     upload_source: 'files/photo.jpg',
                                     content_type: 'image/jpeg')
    puts "File Id: #{file.id}"
    # [END uploadBasic]
    file.id
  end

  def upload_revision(id)
    # [START uploadBasic]
    file_metadata = {}
    file = drive_service.update_file(id,
                                     file_metadata,
                                     fields: 'id',
                                     upload_source: 'files/photo.jpg',
                                     content_type: 'image/jpeg')
    puts "File Id: #{file.id}"
    # [END uploadBasic]
    file.id
  end

  def upload_to_folder(real_folder_id)
    # [START uploadToFolder]
    folder_id = '0BwwA4oUTeiV1TGRPeTVjaWRDY1E'
    # [START_EXCLUDE silent]
    folder_id = real_folder_id
    # [END_EXCLUDE]
    file_metadata = {
        name: 'photo.jpg',
        parents: [folder_id]
    }
    file = drive_service.create_file(file_metadata,
                                     fields: 'id',
                                     upload_source: 'files/photo.jpg',
                                     content_type: 'image/jpeg')
    puts "File Id: #{file.id}"
    # [END uploadToFolder]
    file.id
  end

  def upload_with_conversion
    # [START uploadWithConversion]
    file_metadata = {
        name: 'My Report',
        mime_type: 'application/vnd.google-apps.spreadsheet'
    }
    file = drive_service.create_file(file_metadata,
                                     fields: 'id',
                                     upload_source: 'files/report.csv',
                                     content_type: 'text/csv')
    puts "File Id: #{file.id}"
    # [END uploadWithConversion]
    return file.id
  end

  def export_pdf(real_file_id)
    # [START exportPdf]
    file_id = '1ZdR3L3qP4Bkq8noWLJHSr_iBau0DNT4Kli4SxNc2YEo'
    # [START_EXCLUDE silent]
    file_id = real_file_id
    # [END_EXCLUDE]
    content = drive_service.export_file(file_id,
                                        'application/pdf',
                                        download_dest: StringIO.new)
    # [END exportPdf]
    return content
  end

  def download_file(real_file_id)
    # [START downloadFile]
    file_id = '0BwwA4oUTeiV1UVNwOHItT0xfa2M'
    # [START_EXCLUDE silent]
    file_id = real_file_id
    # [END_EXCLUDE]
    content = drive_service.get_file(file_id, download_dest: StringIO.new)
    # [END downloadFile]
    return content
  end

  def create_shortcut
    # [START createShortcut]
    file_metadata = {
        name: 'Project plan',
        mime_type: 'application/vnd.google-apps.drive-sdk'
    }
    file = drive_service.create_file(file_metadata, fields: 'id')
    puts "File Id: #{file.id}"
    # [END createShortcut]
    return file.id
  end

  def touch_file(real_file_id, real_timestamp)
    # [START touchFile]
    file_id = '1sTWaJ_j7PkjzaBWtNc3IzovK5hQf21FbOw9yLeeLPNQ';
    file_metadata = {
        modified_time: DateTime.now
    }
    # [START_EXCLUDE silent]
    file_id = real_file_id
    file_metadata[:modified_time] = real_timestamp
    # [END_EXCLUDE]
    file = drive_service.update_file(file_id,
                                     file_metadata,
                                     fields: 'id, modifiedTime')
    puts "Modified time: #{file.modified_time}"
    # [END touchFile]
    return file.modified_time
  end

  def create_folder
    # [START createFolder]
    file_metadata = {
        name: 'Invoices',
        mime_type: 'application/vnd.google-apps.folder'
    }
    file = drive_service.create_file(file_metadata, fields: 'id')
    puts "Folder Id: #{file.id}"
    # [END createFolder]
    return file.id
  end

  def move_file_to_folder(real_file_id, real_folder_id)
    # [START moveFileToFolder]
    file_id = '1sTWaJ_j7PkjzaBWtNc3IzovK5hQf21FbOw9yLeeLPNQ'
    folder_id = '0BwwA4oUTeiV1TGRPeTVjaWRDY1E'
    # [START_EXCLUDE silent]
    file_id = real_file_id
    folder_id = real_folder_id
    # [END_EXCLUDE]
    # Retrieve the existing parents to remove
    file = drive_service.get_file(file_id,
                                  fields: 'parents')
    previous_parents = file.parents.join(',')
    # Move the file to the new folder
    file = drive_service.update_file(file_id,
                                     add_parents: folder_id,
                                     remove_parents: previous_parents,
                                     fields: 'id, parents')
    # [END moveFileToFolder]
    return file.parents
  end

  def search_files
    # [START searchFiles]
    files = drive_service.fetch_all(items: :files) do |page_token|
      drive_service.list_files(q: "mimeType='image/jpeg'",
                               spaces: 'drive',
                               fields: 'nextPageToken, files(id, name)',
                               page_token: page_token)
    end
    for file in files
      # Process change
      puts "Found file: #{file.name} #{file.id}"
    end
    # [END searchFiles]
    return files.to_a
  end

  def share_file(real_file_id, real_user, real_domain)
    ids = []
    # [START shareFile]
    file_id = '1sTWaJ_j7PkjzaBWtNc3IzovK5hQf21FbOw9yLeeLPNQ'
    # [START_EXCLUDE silent]
    file_id = real_file_id
    # [END_EXCLUDE]
    callback = lambda do |res, err|
      if err
        # Handle error...
        puts err.body
      else
        puts "Permission ID: #{res.id}"
        # [START_EXCLUDE silent]
        ids << res.id
        # [END_EXCLUDE]
      end
    end
    drive_service.batch do |service|
      user_permission = {
          type: 'user',
          role: 'writer',
          email_address: 'user@example.com'
      }
      # [START_EXCLUDE silent]
      user_permission[:email_address] = real_user
      # [END_EXCLUDE]
      service.create_permission(file_id,
                                user_permission,
                                fields: 'id',
                                &callback)
      domain_permission = {
          type: 'domain',
          role: 'reader',
          domain: 'example.com'
      }
      # [START_EXCLUDE silent]
      domain_permission[:domain] = real_domain
      # [END_EXCLUDE]
      service.create_permission(file_id,
                                domain_permission,
                                fields: 'id',
                                &callback)
    end
    # [END shareFile]
    return ids
  end

  def fetch_start_page_token
    # [START fetchStartPageToken]
    response = drive_service.get_changes_start_page_token
    puts "Start token: #{response.start_page_token}"
    # [END fetchStartPageToken]
    return response.start_page_token
  end

  def fetch_changes(saved_start_page_token)
    # [START fetchChanges]
    # Begin with our last saved start token for this user or the
    # current token from get_changes_start_page_token()
    page_token = saved_start_page_token;
    while page_token do
      response = drive_service.list_changes(page_token,
                                            spaces: 'drive')
      for change in response.changes
        # Process change
        puts "Change found for file: #{change.file_id}"
      end
      if response.new_start_page_token
        # Last page, save this token for the next polling interval
        saved_start_page_token = response.new_start_page_token
      end
      page_token = response.next_page_token
    end
    # [END fetchChanges]
    return saved_start_page_token
  end

  def upload_app_data
    # [START uploadAppData]
    file_metadata = {
        name: 'config.json',
        parents: ['appDataFolder']
    }
    file = drive_service.create_file(file_metadata,
                                     fields: 'id',
                                     upload_source: 'files/config.json',
                                     content_type: 'application/json')
    puts "File Id: #{file.id}"
    # [END uploadAppData]
    file.id
  end

  def list_app_data
    # [START listAppData]
    response = drive_service.list_files(spaces: 'appDataFolder',
                                        fields: 'nextPageToken, files(id, name)',
                                        page_size: 10)
    for file in response.files
      # Process change
      puts "Found file: #{file.name} #{file.id}"
    end
    # [END listAppData]
    return response.files
  end

  def fetch_app_data_folder
    # [START fetchAppDataFolder]
    file = drive_service.get_file('appDataFolder', fields: 'id')
    puts "Folder Id: #{file.id}"
    # [END fetchAppDataFolder]
    file.id
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
