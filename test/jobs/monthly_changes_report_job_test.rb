require 'test_helper'

class MonthlyChangesReportJobTest < ActiveSupport::TestCase

  test 'should produce a report of changes in the last month' do
    refute_path_exists('2024_11_changes.csv')

    MonthlyChangesReportJob.perform_now

    assert_path_exists('2024_11_changes.csv')

    assert FileUtils.compare_file(file_fixture('2024_11_changes.csv'), '2024_11_changes.csv')
  end

  def teardown
    # File.delete('2024_11_changes.csv')
  end

end
