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

require 'google/apis/sheets_v4'

class SpreadsheetSnippets
  def initialize(service)
    @service = service
  end

  def service
    @service
  end

  def create
    # [START sheets_create]
    spreadsheet = {
      properties: {
        title: 'Sales Report'
      }
    }
    spreadsheet = service.create_spreadsheet(spreadsheet,
                                             fields: 'spreadsheetId')
    puts "Spreadsheet ID: #{spreadsheet.spreadsheet_id}"
    # [END sheets_create]
    spreadsheet.spreadsheet_id
  end

  def batch_update(spreadsheet_id, title, find, replacement)
    # [START sheets_batch_update]
    requests = []
    # Change the name of sheet ID '0' (the default first sheet on every
    # spreadsheet)
    requests.push({
                    update_sheet_properties: {
                      properties: { sheet_id: 0, title: 'New Sheet Name' },
                      fields:     'title'
                    }
                  })
    # Find and replace text
    requests.push({
                    find_replace: {
                      find:        find,
                      replacement: replacement,
                      all_sheets:  true
                    }
                  })
    # Add additional requests (operations) ...

    body = { requests: requests }
    result = service.batch_update_spreadsheet(spreadsheet_id, body, {})
    find_replace_response = result.replies[1].find_replace
    puts "#{find_replace_response.occurrences_changed} replacements made."
    # [END sheets_batch_update]
    result
  end

  def get_values(spreadsheet_id, range_name)
    # [START sheets_get_values]
    result = service.get_spreadsheet_values(spreadsheet_id, range_name)
    num_rows = result.values ? result.values.length : 0
    puts "#{num_rows} rows received."
    # [END sheets_get_values]
    result
  end

  def batch_get_values(spreadsheet_id, range)
    # [START sheets_batch_get_values]
    range_names = [
      # Range names ...
    ]
    # [START_EXCLUDE silent]
    range_names = range
    # [END_EXCLUDE]
    result = service.batch_get_spreadsheet_values(spreadsheet_id,
                                                  ranges: range_names)
    puts "#{result.value_ranges.length} ranges retrieved."
    # [END sheets_batch_get_values]
    result
  end

  def update_values(spreadsheet_id, range_name, value_input_option, _values)
    # [START sheets_update_values]
    values = [
      [
        # Cell values ...
      ]
      # Additional rows ...
    ]
    # [START_EXCLUDE silent]
    values = _values
    # [END_EXCLUDE]
    data = [
      {
        range:  range_name,
        values: values
      },
      # Additional ranges to update ...
    ]
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range:  range_name,
                                                                values: values)
    result = service.update_spreadsheet_value(spreadsheet_id,
                                              range_name,
                                              value_range_object,
                                              value_input_option: value_input_option)
    puts "#{result.updated_cells} cells updated."
    # [END sheets_update_values]
    result
  end

  def batch_update_values(spreadsheet_id, range_name, value_input_option, _values)
    # [START sheets_batch_update_values]
    values = [
      [
        # Cell values ...
      ]
      # Additional rows ...
    ]
    # [START_EXCLUDE silent]
    values = _values
    # [END_EXCLUDE]
    data = [
      {
        range:  range_name,
        values: values
      },
      # Additional ranges to update ...
    ]
    batch_update_values = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(
      data:               data,
      value_input_option: value_input_option
    )
    result = service.batch_update_values(spreadsheet_id, batch_update_values)
    puts "#{result.total_updated_cells} cells updated."
    # [END sheets_batch_update_values]
    result
  end

  def append_values(spreadsheet_id, range_name, value_input_option, _values)
    # [START sheets_append_values]
    values = [
      [
        # Cell values ...
      ],
      # Additional rows ...
    ]
    # [START_EXCLUDE silent]
    values = _values
    # [END_EXCLUDE]
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)
    result = service.append_spreadsheet_value(spreadsheet_id,
                                              range_name,
                                              value_range,
                                              value_input_option: value_input_option)
    puts "#{result.updates.updated_cells} cells appended."
    # [END sheets_append_values]
    result
  end

  def pivot_tables(spreadsheet_id)
    # Create two sheets for our pivot table.
    body = {
      requests: [{
        add_sheet: {}
      }, {
        add_sheet: {}
      }]
    }
    batch_update_response = service.batch_update_spreadsheet(spreadsheet_id,
                                                             body,
                                                             {})
    source_sheet_id = batch_update_response.replies[0].add_sheet.properties.sheet_id
    target_sheet_id = batch_update_response.replies[1].add_sheet.properties.sheet_id
    # [START sheets_pivot_tables]
    requests = [{
      update_cells: {
        rows:   {
          values: [
            {
              pivot_table: {
                source:       {
                  sheet_id:           source_sheet_id,
                  start_row_index:    0,
                  start_column_index: 0,
                  end_row_index:      20,
                  end_column_index:   7
                },
                rows:         [
                  {
                    source_column_offset: 1,
                    show_totals:          true,
                    sort_order:           'ASCENDING',
                  },
                ],
                columns:      [
                  {
                    source_column_offset: 4,
                    sort_order:           'ASCENDING',
                    show_totals:          true,
                  }
                ],
                values:       [
                  {
                    summarize_function:   'COUNTA',
                    source_column_offset: 4
                  }
                ],
                value_layout: 'HORIZONTAL'
              }
            }
          ]
        },
        start:  {
          sheet_id:     target_sheet_id,
          row_index:    0,
          column_index: 0
        },
        fields: 'pivotTable'
      }
    }]
    result = service.batch_update_spreadsheet(spreadsheet_id, body, {})
    # [END sheets_pivot_tables]
    result
  end

  def conditional_formatting(spreadsheet_id)
    # [START sheets_conditional_formatting]
    my_range = {
      sheet_id:           0,
      start_row_index:    1,
      end_row_index:      11,
      start_column_index: 0,
      end_column_index:   4
    }
    requests = [{
      add_conditional_format_rule: {
        rule:  {
          ranges:       [my_range],
          boolean_rule: {
            condition: {
              type:   'CUSTOM_FORMULA',
              values: [{ user_entered_value: '=GT($D2,median($D$2:$D$11))' }]
            },
            format:    {
              text_format: { foreground_color: { red: 0.8 } }
            }
          }
        },
        index: 0
      }
    }, {
      add_conditional_format_rule: {
        rule:  {
          ranges:       [my_range],
          boolean_rule: {
            condition: {
              type:   'CUSTOM_FORMULA',
              values: [{ user_entered_value: '=LT($D2,median($D$2:$D$11))' }]
            },
            format:    {
              background_color: { red: 1, green: 0.4, blue: 0.4 }
            }
          }
        },
        index: 0
      }
    }]
    body = {
      requests: requests
    }
    batch_update = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
    batch_update.requests = requests
    result = service.batch_update_spreadsheet(spreadsheet_id, batch_update)
    puts "#{result.replies.length} cells updated."
    # [END sheets_conditional_formatting]
    result
  end
end
