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
require "team_drive_snippets"

RSpec.describe TeamDriveSnippets do
  include TestHelpers

  before :all do
    @snippets = TeamDriveSnippets.new build_oauth_service
    reset
  end

  after service.run_script do
    cleanup_files
  end

  # it "should create a team drive" do
  #   id = @snippets.create_team_drive
  #   expect(id).to_not be_nil
  #   drive_service.delete_teamdrive(id)
  # end

  # it "should recover an orphaned team drive" do
  #   id = self.create_orphaned_team_drive
  #   team_drives = @snippets.recover_team_drives("sbazyl@test.appsdevtesting.com")
  #   expect(team_drives.length).to_not eq 0
  #   drive_service.delete_teamdrive(id)
  # end

  def create_orphaned_team_drive
    team_drive_id = @snippets.create_team_drive
    permissions = drive_service.list_permissions(team_drive_id,
                                                 supports_team_drives: true)
    permissions.permissions.each do |permission|
      drive_service.delete_permission(team_drive_id,
                                      permission.id,
                                      supports_team_drives: true)
    end
    team_drive_id
  end
end
