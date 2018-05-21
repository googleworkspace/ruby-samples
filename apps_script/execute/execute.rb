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
# [START apps_script_execute]
SCRIPT_ID = 'ENTER_YOUR_SCRIPT_ID_HERE'

# Create an execution request object.
request = Google::Apis::ScriptV1::ExecutionRequest.new(
  function: 'getFoldersUnderRoot'
)

begin
  # Make the API request.
  resp = service.run_script(SCRIPT_ID, request)

  if resp.error
    # The API executed, but the script returned an error.

    # Extract the first (and only) set of error details. The values of this
    # object are the script's 'errorMessage' and 'errorType', and an array of
    # stack trace elements.
    error = resp.error.details[0]

    puts "Script error message: #{error['errorMessage']}"

    if error['scriptStackTraceElements']
      # There may not be a stacktrace if the script didn't start executing.
      puts "Script error stacktrace:"
      error['scriptStackTraceElements'].each do |trace|
        puts "\t#{trace['function']}: #{trace['lineNumber']}"
      end
    end
  else
    # The structure of the result will depend upon what the Apps Script function
    # returns. Here, the function returns an Apps Script Object with String keys
    # and values, and so the result is treated as a Ruby hash (folderSet).
    folder_set = resp.response['result']
    if folder_set.length == 0
      puts "No folders returned!"
    else
      puts "Folders under your root folder:"
      folder_set.each do |id, folder|
        puts "\t#{folder} (#{id})"
      end
    end
  end
rescue Google::Apis::ClientError
  # The API encountered a problem before the script started executing.
  puts "Error calling API!"
end
// [END apps_script_execute]
