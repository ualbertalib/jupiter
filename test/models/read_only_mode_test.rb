require 'test_helper'

class ReadOnlyModeTest < ActiveSupport::TestCase

  test 'no more than one record' do
    read_only_mode = ReadOnlyMode.new
    assert_not read_only_mode.valid?
    assert_includes read_only_mode.errors[:enabled], 'Only one ReadOnlyMode record may exist'
  end

  test 'default for enabled is false' do
    ReadOnlyMode.destroy_all
    ReadOnlyMode.new.save!
    read_only_mode = ReadOnlyMode.first
    assert_not read_only_mode.enabled?
  end

end
