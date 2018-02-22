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
require 'spreadsheet_snippets'

VALUES_2D = [
  %w[A B],
  %w[C D]
].freeze

RSpec.describe SpreadsheetSnippets do
  include TestHelpers

  before(:all) do
    @snippets = SpreadsheetSnippets.new(build_service)
    reset
  end

  after(:all) do
    cleanup_files
  end

  it 'should create a spreadsheet' do
    id = @snippets.create
    expect(id).to_not be_nil
    delete_file_on_cleanup(id)
  end

  it 'should batch update a spreadsheet' do
    id = create_test_spreadsheet
    populate_values(id)
    result = @snippets.batch_update(id, 'New Title', 'Hello', 'Goodbye')
    expect(result.replies.length).to eq(2)
    find_replace_response = result.replies[1].find_replace
    expect(find_replace_response.occurrences_changed).to eq(100)
  end

  it 'should get values' do
    id = create_test_spreadsheet
    populate_values(id)
    result = @snippets.get_values(id, 'A1:C2')
    expect(result).to_not be_nil
    values = result.values
    expect(values).to_not be_nil
    expect(values.length).to eq(2)
    expect(values[0].length).to eq(3)
  end

  it 'should batch get values' do
    id = create_test_spreadsheet
    populate_values(id)
    result = @snippets.batch_get_values(id, ['A1:A3', 'B1:C1'])
    value_ranges = result.value_ranges
    expect(result).to_not be_nil
    expect(value_ranges.length).to eq(2)
    values = value_ranges[0].values
    expect(values.length).to eq(3)
  end

  it 'should update values' do
    id = create_test_spreadsheet
    result = @snippets.update_values(id, 'A1:B2', 'USER_ENTERED', VALUES_2D)
    expect(result).to_not be_nil
    expect(result.updated_rows).to eq(2)
    expect(result.updated_columns).to eq(2)
    expect(result.updated_cells).to eq(4)
  end

  it 'should batch update values' do
    id = create_test_spreadsheet
    result = @snippets.batch_update_values(id, 'A1:B2', 'USER_ENTERED', VALUES_2D)
    expect(result).to_not be_nil
    responses = result.responses
    expect(responses.length).to eq(1)
    expect(responses[0].updated_rows).to eq(2)
    expect(responses[0].updated_columns).to eq(2)
  end

  it 'should append values' do
    id = create_test_spreadsheet
    populate_values(id)
    result = @snippets.append_values(id, 'Sheet1', 'USER_ENTERED', VALUES_2D)
    expect(result).to_not be_nil
    expect(result.table_range).to eq('Sheet1!A1:J10')
    updates = result.updates
    expect(updates.updated_range).to eq('Sheet1!A11:B12')
    expect(updates.updated_rows).to eq(2)
    expect(updates.updated_columns).to eq(2)
    expect(updates.updated_cells).to eq(4)
  end

  it 'should create pivot tables' do
    id = create_test_spreadsheet
    populate_values(id)
    result = @snippets.pivot_tables(id)
    expect(result).to_not be_nil
  end

  it 'should conditionally format' do
    id = create_test_spreadsheet
    populate_values(id)
    result = @snippets.conditional_formatting(id)
    expect(result.spreadsheet_id).to eq(id)
    expect(result.replies.length).to eq(2)
  end
end
