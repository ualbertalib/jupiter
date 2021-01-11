require 'test_helper'

class ReadOnlyServiceTest < ActiveSupport::TestCase

  test 'can turn read only mode on and off' do
    read_only_service = ReadOnlyService.new
    assert_not ReadOnlyMode.first.enabled?
    read_only_service.enable
    assert ReadOnlyMode.first.enabled?
    read_only_service.disable
    assert_not ReadOnlyMode.first.enabled?
  end

end
