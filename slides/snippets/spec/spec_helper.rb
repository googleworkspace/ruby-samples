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
require 'google/apis/slides_v1'
require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'

module TestHelpers
  def build_drive_service
    drive = Google::Apis::DriveV3::DriveService.new
    drive.authorization = Google::Auth.get_application_default(
      [Google::Apis::DriveV3::AUTH_DRIVE,
       Google::Apis::DriveV3::AUTH_DRIVE_APPDATA]
    )
    drive
  end

  def build_slides_service
    slides = Google::Apis::SlidesV1::SlidesService.new
    slides.authorization = Google::Auth.get_application_default(
      [Google::Apis::SlidesV1::AUTH_PRESENTATIONS,
       Google::Apis::SheetsV4::AUTH_SPREADSHEETS]
    )
    slides
  end

  def build_sheets_service
    sheets = Google::Apis::SheetsV4::SheetsService.new
    sheets.authorization = Google::Auth.get_application_default(
      [Google::Apis::SheetsV4::AUTH_SPREADSHEETS]
    )
    sheets
  end

  def drive_service
    @drive_service ||= build_drive_service
  end

  def slides_service
    @slides_service ||= build_slides_service
  end

  def sheets_service
    @sheets_service ||= build_sheets_service
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

  def create_test_presentation
    presentation = slides_service.create_presentation(
      'title' => 'Test Preso'
    )
    presentation.presentation_id
  end

  def delete_file_on_cleanup(file_id)
    @files_to_delete << file_id
  end

  def add_slides(presentation_id, num, layout = 'TITLE_AND_TWO_COLUMNS')
    requests = []
    slide_ids = []
    (0..num).each do |i|
      slide_ids << "slide_#{i}"
      requests << {
        create_slide: {
          object_id_prop: slide_ids[i],
          slide_layout_reference: {
            predefined_layout: layout
          }
        }
      }
    end

    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    slides_service.batch_update_presentation(presentation_id, req)
    slide_ids
  end

  def create_test_textbox(presentation_id, page_id)
    box_id = 'MyTextBox_01'
    pt350 = {
      magnitude: 350,
      unit: 'PT'
    }
    requests = [] << {
      create_shape: {
        object_id_prop: box_id,
        shape_type: 'TEXT_BOX',
        element_properties: {
          page_object_id: page_id,
          size: {
            height: pt350,
            width: pt350
          },
          transform: {
            scale_x: 1,
            scale_y: 1,
            translate_x: 350,
            translate_y: 100,
            unit: 'PT'
          }
        }
      }
    } << {
      insert_text: {
        object_id_prop: box_id,
        insertion_index: 0,
        text: 'New Box Text Inserted'
      }
    }

    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)
    response.replies[0].create_shape.object_id_prop
  end

  def create_test_sheets_chart(presentation_id, page_id, spreadsheet_id, sheet_chart_id)
    chart_id = 'MyChart_01'
    emu4m = {
      magnitude: 4_000_000,
      unit: 'EMU'
    }
    requests = [] << {
      create_sheets_chart: {
        object_id_prop: chart_id,
        spreadsheet_id: spreadsheet_id,
        chart_id: sheet_chart_id,
        linking_mode: 'LINKED',
        element_properties: {
          page_object_id: page_id,
          size: {
            height: emu4m,
            width: emu4m
          },
          transform: {
            scale_x: 1,
            scale_y: 1,
            translate_x: 100_000,
            translate_y: 100_000,
            unit: 'EMU'
          }
        }
      }
    }

    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)
    response.replies[0].create_sheets_chart.object_id_prop
  end
end
