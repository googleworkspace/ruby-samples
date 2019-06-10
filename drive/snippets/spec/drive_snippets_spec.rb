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

require "spec_helper"
require "drive_snippets"

RSpec.describe DriveSnippets do
  include TestHelpers

  before :all do
    @snippets = DriveSnippets.new build_service
    reset
  end

  after :all do
    cleanup_files
  end

  it "should upload a photo" do
    file_id = @snippets.upload_basic
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should upload a revision" do
    file_id = @snippets.upload_basic
    file_id = @snippets.upload_revision file_id
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should upload to a folder" do
    folder_id = @snippets.create_folder
    delete_file_on_cleanup folder_id
    file_id = @snippets.upload_to_folder folder_id
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should upload and convert" do
    file_id = @snippets.upload_with_conversion
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should export a PDF" do
    file_id = create_test_document
    content = @snippets.export_pdf file_id
    content = content.string
    expect(content.length).to_not be 0
    expect(content.slice(0, 4)).to eq "%PDF"
  end

  it "should download a file" do
    file_id = create_test_blob
    content = @snippets.download_file file_id
    content = content.string
    expect(content.length).to_not eq 0
    expect(content[0]).to eq "\xFF"
    expect(content[1]).to eq "\xD8"
  end

  it "should create a short cut" do
    file_id = @snippets.create_shortcut
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should update the modified time" do
    file_id = create_test_blob
    now = DateTime.now
    now = DateTime.new(now.year, now.month, now.day, now.hour, now.minute,
                       now.second)
    modified_time = @snippets.touch_file file_id, now
    expect(modified_time).to eq(now)
  end

  it "should create a folder" do
    file_id = @snippets.create_folder
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should move a file to a folder" do
    folder_id = @snippets.create_folder
    delete_file_on_cleanup folder_id
    file_id = create_test_blob
    parents = @snippets.move_file_to_folder file_id, folder_id
    expect(parents).to include folder_id
    expect(parents.length).to eq 1
  end

  it "should search files" do
    create_test_blob
    files = @snippets.search_files
    expect(files.length).to_not eq 0
  end

  it "should share files" do
    file_id = create_test_blob
    ids = @snippets.share_file file_id, "user@test.appsdevtesting.com", "test.appsdevtesting.com"
    expect(ids.length).to eq 2
  end

  it "should get the starting page token" do
    token = @snippets.fetch_start_page_token
    expect(token).to_not be_nil
  end

  it "should fetch changes" do
    start_token = @snippets.fetch_start_page_token
    create_test_blob
    token = @snippets.fetch_changes start_token
    expect(token).to_not be_nil
    expect(token).to_not eq start_token
  end

  it "should upload a photo" do
    file_id = @snippets.upload_app_data
    expect(file_id).to_not be_nil
    delete_file_on_cleanup file_id
  end

  it "should list files" do
    file_id = @snippets.upload_app_data
    delete_file_on_cleanup file_id
    files = @snippets.list_app_data
    expect(files.length).to_not eq 0
  end

  it "should fetch the app data folder" do
    file_id = @snippets.fetch_app_data_folder
    expect(file_id).to_not be_nil
  end
end
