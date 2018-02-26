require 'test_helper'

class StatisticsTest < ActiveSupport::TestCase

  test 'counts are zero for unviewed objects' do
    obj_id = generate_random_string

    assert_equal 0, Statistics.views_for(item_id: obj_id)
    assert_equal 0, Statistics.downloads_for(item_id: obj_id)
    assert_equal [0, 0], Statistics.for(item_id: obj_id)
  end

  test 'counts increment correctly' do
    obj_id = generate_random_string
    test_ip = '192.168.0.1'

    freeze_time do
      Statistics.increment_view_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 1, Statistics.views_for(item_id: obj_id)
      assert_equal [1, 0], Statistics.for(item_id: obj_id)

      # a second view inside the same time period is ignored
      Statistics.increment_view_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 1, Statistics.views_for(item_id: obj_id)
      assert_equal [1, 0], Statistics.for(item_id: obj_id)

      # downloads work equally

      Statistics.increment_download_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 1, Statistics.downloads_for(item_id: obj_id)
      assert_equal [1, 1], Statistics.for(item_id: obj_id)

      Statistics.increment_download_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 1, Statistics.downloads_for(item_id: obj_id)
      assert_equal [1, 1], Statistics.for(item_id: obj_id)

      # simulate expiring key at top of hour in order to test behaviour after ip filter rotation
      views_key = Statistics.send(:uniques_key_for, :view, obj_id)
      downloads_key = Statistics.send(:uniques_key_for, :download, obj_id)
      # clear current timeout
      Redis.current.persist views_key
      Redis.current.persist downloads_key
      # expire immediately
      Redis.current.pexpire views_key, -1
      Redis.current.pexpire downloads_key, -1

      # Susequent viewings outside the ip filter expiry period should now count
      Statistics.increment_view_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 2, Statistics.views_for(item_id: obj_id)
      assert_equal [2, 1], Statistics.for(item_id: obj_id)

      # a second view inside the same time period is still ignored
      Statistics.increment_view_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 2, Statistics.views_for(item_id: obj_id)
      assert_equal [2, 1], Statistics.for(item_id: obj_id)

      Statistics.increment_download_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 2, Statistics.downloads_for(item_id: obj_id)
      assert_equal [2, 2], Statistics.for(item_id: obj_id)

      Statistics.increment_download_count_for(item_id: obj_id, ip: test_ip)
      assert_equal 2, Statistics.downloads_for(item_id: obj_id)
      assert_equal [2, 2], Statistics.for(item_id: obj_id)
    end
  end

end
