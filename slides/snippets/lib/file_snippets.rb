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
require 'google/apis/slides_v1'

class FileSnippets
  def initialize(drive_service, slides_service, sheets_service)
    @drive_service = drive_service
    @slides_service = slides_service
    @sheets_service = sheets_service
  end

  def drive_service
    @drive_service
  end

  def slides_service
    @slides_service
  end

  def sheets_service
    @sheets_service
  end

  def create_presentation(title='Title')
    # [START slides_create_presentation]
    body = Google::Apis::SlidesV1::Presentation.new
    body.title =  title
    presentation = slides_service.create_presentation(body)
    puts "Created presentation with ID: #{presentation.presentation_id}"
    # [END slides_create_presentation]
    presentation
  end

  def copy_presentation(presentation_id, copy_title)
    # [START slides_copy_presentation]
    body = Google::Apis::SlidesV1::Presentation.new
    body.title = copy_title
    drive_response = drive_service.copy_file(presentation_id, body)
    puts drive_response
    presentation_copy_id = drive_response.id
    # [END slides_copy_presentation]
    presentation_copy_id
  end

  def create_slide(presentation_id, page_id)
    # [START slides_create_slide]
    body = Google::Apis::SlidesV1::Presentation.new
    requests = [{
      create_slide: {
        object_id_prop: page_id,
        insertion_index: '1',
        slide_layout_reference: {
          predefined_layout: 'TITLE_AND_TWO_COLUMNS'
        }
      }
    }]

    # If you wish to populate the slide with elements, add element create requests here,
    # using the page_id.

    # Execute the request.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)
    create_slide_response = response.replies[0].create_slide
    puts "Created slide with ID: #{create_slide_response.object_id}"
    # [END slides_create_slide]
    create_slide_response
  end

  def create_textbox_with_text(presentation_id, page_id)
    # [START slides_create_textbox_with_text]
    # Create a new square textbox, using the supplied element ID.
    element_id = 'MyTextBox_01'
    pt350 = {
      magnitude: '350',
      unit: 'PT'
    }
    requests = [{
      create_shape: {
        object_id_prop: element_id,
        shape_type: 'TEXT_BOX',
        element_properties: {
          page_object_id: page_id,
          size: {
            height: pt350,
            width: pt350
          },
          transform: {
            scale_x: '1',
            scale_y: '1',
            translate_x: '350',
            translate_y: '100',
            unit: 'PT'
          }
        }
      }
    },

    # Insert text into the box, using the supplied element ID.
    {
      insert_text: {
        object_id_prop: element_id,
        insertion_index: 0,
        text: 'New Box Text Inserted!'
      }
    }]

    # Execute the request.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(
      presentation_id,
      req)
    create_shape_response = response.replies[0].create_shape
    puts "Created textbox with ID: #{create_shape_response.object_id}"
    # [END slides_create_textbox_with_text]
    response
  end

  def create_image(presentation_id, page_id, image_file_path, image_mimetype)
    # [START slides_create_image]
    # Temporarily upload a local image file to Drive, in order to obtain a URL
    # for the image. Alternatively, you can provide the Slides servcie a URL of
    # an already hosted image.
    #
    # We will use an existing image under the variable: IMAGE_URL.
    #
    # Create a new image, using the supplied object ID, with content downloaded from image_url.
    requests = []
    image_id = 'MyImage_01'
    emu4M = {
      magnitude: '4000000',
      unit: 'EMU'
    }
    requests << {
      create_image: {
        object_id_prop: image_id,
        url: IMAGE_URL,
        element_properties: {
          page_object_id: page_id,
          size: {
            height: emu4M,
            width: emu4M
          },
          transform: {
            scale_x: '1',
            scale_y: '1',
            translate_x: '100000',
            translate_y: '100000',
            unit: 'EMU'
          }
        }
      }
    }

    # Execute the request.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(
      presentation_id,
      req)
    create_image_response = response.replies[0].create_image
    puts "Created image with ID: #{create_image_response.object_id}"
    # [END slides_create_image]
    response
  end

  def text_merging(template_presentation_id, data_spreadsheet_id)
    responses = []
    # [START slides_text_merging]
    # Use the Sheets API to load data, one record per row.
    data_range_notation = 'Customers!A2:M6'
    sheets_response = sheets_service.get_spreadsheet_values(
      data_spreadsheet_id,
      data_range_notation)
    values = sheets_response.values

    # For each record, create a new merged presentation.
    values.each do |row|
      customer_name = row[2]       # name in column 3
      case_description = row[5]    # case description in column 6
      total_portfolio = row[11]    # total portfolio in column 12

      # Duplicate the template presentation using the Drive API.
      copy_title = customer_name + ' presentation'
      body = Google::Apis::SlidesV1::Presentation.new
      body.title = copy_title
      drive_response = drive_service.copy_file(template_presentation_id, body)
      presentation_copy_id = drive_response.id

      # Create the text merge (replace_all_text) requests for this presentation.
      requests = [] << {
        replace_all_text: {
          contains_text: {
            text: '{{customer-name}}',
            match_case: true
          },
          replace_text: customer_name
        }
      } << {
        replace_all_text: {
          contains_text: {
            text: '{{case-description}}',
            match_case: true
          },
          replace_text: case_description
        }
      } << {
        replace_all_text: {
          contains_text: {
            text: '{{total-portfolio}}',
            match_case: true
          },
          replace_text: total_portfolio
        }
      }

      # Execute the requests for this presentation.
      req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
      response = slides_service.batch_update_presentation(
        presentation_copy_id,
        req)
      # [START_EXCLUDE silent]
      responses << response
      # [END_EXCLUDE silent]
      # Count the total number of replacements made.
      num_replacements = 0
      response.replies.each do |reply|
        num_replacements += reply.replace_all_text.occurrences_changed
      end
      puts "Created presentation for #{customer_name} with ID: #{presentation_copy_id}"
      puts "Replaced #{num_replacements} text instances"
    end
    # [END slides_text_merging]
    responses
  end

  def image_merging(template_presentation_id, image_url, customer_name)
    logo_url = image_url
    customer_graphic_url = image_url

    # [START slides_image_merging]
    # Duplicate the template presentation using the Drive API.
    copy_title = customer_name + ' presentation'
    body = Google::Apis::SlidesV1::Presentation.new
    body.title = copy_title
    drive_response = drive_service.copy_file(template_presentation_id, body)
    presentation_copy_id = drive_response.id

    # Create the image merge (replace_all_shapes_with_image) requests.
    requests = [] << {
      replace_all_shapes_with_image: {
        image_url: logo_url,
        replace_method: 'CENTER_INSIDE',
        contains_text: {
          text: '{{company-logo}}',
          match_case: true
        }
      }
    } << {
      replace_all_shapes_with_image: {
        image_url: customer_graphic_url,
        replace_method: 'CENTER_INSIDE',
        contains_text: {
          text: '{{customer-graphic}}',
          match_case: true
        }
      }
    }

    # Execute the requests.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(
      presentation_copy_id,
      req)

    # Count the number of replacements made.
    num_replacements = 0
    response.replies.each do |reply|
      num_replacements += reply.replace_all_shapes_with_image.occurrences_changed
    end
    puts "Created presentation for #{customer_name} with ID: #{presentation_copy_id}"
    puts "Replaced #{num_replacements} shapes with images"
    # [END slides_image_merging]
    response
  end

  def simple_text_replace(presentation_id, shape_id, replacement_text)
    # [START slides_simple_text_replace]
    # Remove existing text in the shape, then insert new text.
    requests = [] << {
      delete_text: {
        object_id_prop: shape_id,
        text_range: {
          type: 'ALL'
        }
      }
    } << {
      insert_text: {
        object_id_prop: shape_id,
        insertion_index: 0,
        text: replacement_text
      }
    }

    # Execute the requests.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(
      presentation_id,
      req)
    puts "Replaced text in shape with ID: #{shape_id}"
    # [END slides_simple_text_replace]
    response
  end

  def text_style_update(presentation_id, shape_id)
    # [START slides_text_style_update]
    # Update the text style so that the first 5 characters are bolded
    # and italicized, the next 5 are displayed in blue 14 pt Times
    # New Roman font, and the next 5 are hyperlinked.
    requests = [] << {
      update_text_style: {
        object_id_prop: shape_id,
        text_range: {
          type: 'FIXED_RANGE',
          start_index: 0,
          end_index: 5
        },
        style: {
          bold: true,
          italic: true
        },
        fields: 'bold,italic'
      }
    } << {
      update_text_style: {
        object_id_prop: shape_id,
        text_range: {
          type: 'FIXED_RANGE',
          start_index: 5,
          end_index: 10
        },
        style: {
          font_family: 'Times New Roman',
          font_size: {
            magnitude: 14,
            unit: 'PT'
          },
          foreground_color: {
            opaque_color: {
              rgb_color: {
                blue: 1.0,
                green: 0.0,
                red: 0.0
              }
            }
          }
        },
        fields: 'foreground_color,font_family,font_size'
      }
    } << {
      update_text_style: {
        object_id_prop: shape_id,
        text_range: {
          type: 'FIXED_RANGE',
          start_index: 10,
          end_index: 15
        },
        style: {
          link: {
            url: 'www.example.com'
          }
        },
        fields: 'link'
      }
    }

    # Execute the requests.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)
    puts "Updated the text style for shape with ID: #{shape_id}"
    # [END slides_text_style_update]
    response
  end

  def create_bulleted_text(presentation_id, shape_id)
    # [START slides_create_bulleted_text]
    # Add arrow-diamond-disc bullets to all text in the shape.
    requests = [] << {
      create_paragraph_bullets: {
        object_id_prop: shape_id,
        text_range: {
          type: 'ALL'
        },
        bulletPreset: 'BULLET_ARROW_DIAMOND_DISC'
      }
    }

    # Execute the requests.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)
    puts "Added bullets to text in shape with ID: #{shape_id}"
    # [END slides_create_bulleted_text]
    response
  end

  def create_sheets_chart(presentation_id, page_id, spreadsheet_id, sheet_chart_id)
    # [START slides_create_sheets_chart]
    # Embed a Sheets chart (indicated by the spreadsheet_id and sheet_chart_id) onto
    # a page in the presentation. Setting the linking mode as "LINKED" allows the
    # chart to be refreshed if the Sheets version is updated.
    emu4M = {
      magnitude: 4000000,
      unit: 'EMU'
    }
    presentation_chart_id = 'my_embedded_chart'
    requests = [{
      create_sheets_chart: {
        object_id_prop: presentation_chart_id,
        spreadsheet_id: spreadsheet_id,
        chart_id: sheet_chart_id,
        linking_mode: 'LINKED',
        element_properties: {
          page_object_id: page_id,
          size: {
            height: emu4M,
            width: emu4M
          },
          transform: {
            scale_x: 1,
            scale_y: 1,
            translate_x: 100000,
            translate_y: 100000,
            unit: 'EMU'
          }
        }
      }
    }]

    # Execute the request.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)

    puts "Added a linked Sheets chart with ID: #{presentation_chart_id}"
    # [END slides_create_sheets_chart]
    response
  end

  def refresh_sheets_chart(presentation_id, presentation_chart_id)
    # [START slides_refresh_sheets_chart]
    # Refresh an existing linked Sheets chart embedded in a presentation.
    requests = [{
      refresh_sheets_chart: {
        object_id_prop: presentation_chart_id
      }
    }]

    # Execute the request.
    req = Google::Apis::SlidesV1::BatchUpdatePresentationRequest.new(requests: requests)
    response = slides_service.batch_update_presentation(presentation_id, req)

    puts "Refreshed a linked Sheets chart with ID: #{presentation_chart_id}"
    # [END slides_refresh_sheets_chart]
    response
  end
end
