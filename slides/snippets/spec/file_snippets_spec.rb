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

require 'spec_helper'
require 'file_snippets'

RSpec.describe FileSnippets do
  include TestHelpers

  IMAGE_FILE_PATH = '../images/googlelogo_color_272x92dp.png'.freeze
  IMAGE_URL = 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png'.freeze
  IMAGE_MIMETYPE = 'image/png'.freeze
  TEMPLATE_PRESENTATION_ID = '1MmTR712m7U_kgeweE57POWwkEyWAV17AVAWjpmltmIg'.freeze
  DATA_SPREADSHEET_ID = '14KaZMq2aCAGt5acV77zaA_Ps8aDt04G7T0ei4KiXLX8'.freeze
  CHART_ID = 1107320627 # rubocop:disable Style/NumericLiterals
  CUSTOMER_NAME = 'Fake Customer'.freeze

  before(:all) do
    @snippets = FileSnippets.new(build_drive_service,
                                 build_slides_service,
                                 build_sheets_service)
    reset
  end

  after(:all) do
    cleanup_files
  end

  it 'should create a presentation' do
    presentation = @snippets.create_presentation('Title')
    expect(presentation).to_not be_nil
    delete_file_on_cleanup(presentation.presentation_id)
  end

  it 'should copy a presentation' do
    presentation_id = create_test_presentation
    copy_id = @snippets.copy_presentation(presentation_id, 'My Duplicate Presentation')
    expect(copy_id).to_not be_nil
    delete_file_on_cleanup(copy_id)
  end

  it 'should create a slide' do
    presentation_id = create_test_presentation
    add_slides(presentation_id, 3, 'TITLE_AND_TWO_COLUMNS')
    page_id = 'my_page_id'
    response = @snippets.create_slide(presentation_id, page_id)
    expect(response.object_id_prop).to eq(page_id)
    delete_file_on_cleanup(presentation_id)
  end

  it 'should create a textbox with text' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    response = @snippets.create_textbox_with_text(presentation_id, page_id)
    expect(response.replies.length).to eq(2)
    box_id = response.replies[0].create_shape.object_id_prop
    expect(box_id).to_not be_nil
  end

  it 'should create an image' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    response = @snippets.create_image(presentation_id, page_id, IMAGE_FILE_PATH, IMAGE_MIMETYPE)
    expect(response.replies.length).to eq(1)
    image_id = response.replies[0].create_image.object_id_prop
    expect(image_id).to_not be_nil
  end

  it 'should text merge' do
    responses = @snippets.text_merging(TEMPLATE_PRESENTATION_ID, DATA_SPREADSHEET_ID)
    responses.each do |response|
      presentation_id = response.presentation_id
      expect(presentation_id).to_not be_nil
      expect(response.replies.length).to eq(3)
      num_replacements = 0
      response.replies.each do |reply|
        num_replacements += reply.replace_all_text.occurrences_changed
      end
      expect(num_replacements).to eq(4)
      delete_file_on_cleanup(presentation_id)
    end
  end

  it 'should image merge' do
    response = @snippets.image_merging(TEMPLATE_PRESENTATION_ID,
                                       IMAGE_URL,
                                       CUSTOMER_NAME)
    presentation_id = response.presentation_id
    expect(presentation_id).to_not be_nil
    expect(response.replies.length).to eq(2)
    num_replacements = 0
    response.replies.each do |reply|
      num_replacements += reply.replace_all_shapes_with_image.occurrences_changed
    end
    expect(num_replacements).to eq(2)
    delete_file_on_cleanup(presentation_id)
  end

  it 'should simple text replace' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    box_id = create_test_textbox(presentation_id, page_id)
    response = @snippets.simple_text_replace(presentation_id, box_id, 'MY NEW TEXT')
    expect(response.replies.length).to eq(2)
  end

  it 'should text style update' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    box_id = create_test_textbox(presentation_id, page_id)
    response = @snippets.text_style_update(presentation_id, box_id)
    expect(response.replies.length).to eq(3)
  end

  it 'should create bulleted text' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    box_id = create_test_textbox(presentation_id, page_id)
    response = @snippets.create_bulleted_text(presentation_id, box_id)
    expect(response.replies.length).to eq(1)
  end

  it 'should create a sheets chart' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    response = @snippets.create_sheets_chart(presentation_id,
                                             page_id,
                                             DATA_SPREADSHEET_ID,
                                             CHART_ID)
    expect(response.replies.length).to eq(1)
    chart_id = response.replies[0].create_sheets_chart.object_id_prop
    expect(chart_id).to_not be_nil
  end

  it 'should refresh sheets chart' do
    presentation_id = create_test_presentation
    page_id = add_slides(presentation_id, 1, 'BLANK')[0]
    chart_id = create_test_sheets_chart(presentation_id,
                                        page_id,
                                        DATA_SPREADSHEET_ID,
                                        CHART_ID)
    response = @snippets.refresh_sheets_chart(presentation_id,
                                              chart_id)
    expect(response.replies.length).to eq(1)
  end
end
