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

spec_dir = __dir__
root_dir = File.expand_path(File.join(spec_dir, '..'))
lib_dir = File.expand_path(File.join(root_dir, 'lib'))

$LOAD_PATH.unshift(spec_dir)
$LOAD_PATH.unshift(lib_dir)
$LOAD_PATH.uniq!

require 'rspec'
require 'googleauth'
require 'google/apis/drive_v3'

module TestHelpers
  # Builds a DriveService with a service account
  def build_service
    drive = Google::Apis::DriveV3::DriveService.new
    drive.authorization = Google::Auth.get_application_default(
      [Google::Apis::DriveV3::AUTH_DRIVE,
       Google::Apis::DriveV3::AUTH_DRIVE_APPDATA]
    )
    drive
  end

  # Builds a DriveService with an OAuth client ID
  def build_oauth_service
    # TODO
  end

  def drive_service
    @drive_service ||= build_service
  end

  def reset
    @files_to_delete = []
  end

  def cleanup_files
    @files_to_delete ||= []
    return if @files_to_delete.empty?

    drive_service.batch do
      @files_to_delete.each do |file_id|
        puts "Deleting file #{file_id}"
        drive_service.delete_file(file_id) do |res, err|
          # Ignore errors...
        end
      end
    end
  end

  def delete_file_on_cleanup(file_id)
    @files_to_delete << file_id
  end

  def create_test_blob
    file_metadata = { name: 'photo.jpg' }
    file = drive_service.create_file(file_metadata,
                                     upload_source: 'files/photo.jpg',
                                     content_type:  'image/jpeg')
    delete_file_on_cleanup(file.id)
    file.id
  end

  def create_test_document
    file_metadata = {
      name:      'Test Document',
      mime_type: 'application/vnd.google-apps.document'
    }
    file = drive_service.create_file(file_metadata,
                                     upload_source: 'files/document.txt',
                                     content_type:  'text/plain')
    delete_file_on_cleanup(file.id)
    file.id
  end
end
