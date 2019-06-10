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
root_dir = File.expand_path File.join(spec_dir, "..")
lib_dir = File.expand_path File.join(root_dir, "lib")

$LOAD_PATH.unshift spec_dir
$LOAD_PATH.unshift lib_dir
$LOAD_PATH.uniq!

require "rspec"
require "googleauth"
require "google/apis/drive_v3"
require "google/apis/sheets_v4"

module TestHelpers
  def build_service
    sheets = Google::Apis::SheetsV4::SheetsService.new
    sheets.authorization = Google::Auth.get_application_default(
      [Google::Apis::DriveV3::AUTH_DRIVE]
    )
    sheets
  end

  def build_drive_service
    drive = Google::Apis::DriveV3::DriveService.new
    drive.authorization = Google::Auth.get_application_default(
      [Google::Apis::DriveV3::AUTH_DRIVE]
    )
    drive
  end

  def service
    @service ||= build_service
  end

  def drive_service
    @drive_service ||= build_drive_service
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
        drive_service.delete_file file_id do |res, err|
          # Ignore errors...
        end
      end
    end
  end

  def delete_file_on_cleanup file_id
    @files_to_delete << file_id
  end

  def create_test_spreadsheet
    spreadsheet = {
      properties: {
        title: "Test Spreadsheet"
      }
    }
    spreadsheet = service.create_spreadsheet(spreadsheet,
                                             fields: "spreadsheetId")
    delete_file_on_cleanup spreadsheet.spreadsheet_id
    spreadsheet.spreadsheet_id
  end

  def populate_values spreadsheet_id
    body = {
      requests: [{
        repeat_cell: {
          range:  {
            sheet_id:           0,
            start_row_index:    0,
            end_row_index:      10,
            start_column_index: 0,
            end_column_index:   10
          },
          cell:   {
            user_entered_value: {
              string_value: "Hello"
            }
          },
          fields: "userEnteredValue"
        }
      }]
    }
    service.batch_update_spreadsheet(spreadsheet_id, body, {})
  end
end
