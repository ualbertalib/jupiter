require 'test_helper'

class StatisticsTest < ActiveSupport::TestCase

  setup do
    @obj_id = generate_random_string
    @test_ip = '192.168.0.1'
  end

  test 'counts are zero for unviewed objects' do
    obj_id = generate_random_string

    assert_equal 0, Statistics.views_for(item_id: obj_id)
    assert_equal 0, Statistics.downloads_for(item_id: obj_id)
    assert_equal [0, 0], Statistics.for(item_id: obj_id)
  end

  test 'view counts increment correctly' do
    freeze_time do
      Statistics.increment_view_count_for(item_id: @obj_id, ip: @test_ip)
      assert_equal 1, Statistics.views_for(item_id: @obj_id)
      assert_equal [1, 0], Statistics.for(item_id: obj_id)

      # a second view inside the same time period is ignored
      Statistics.increment_view_count_for(item_id: @obj_id, ip: @test_ip)
      assert_equal 1, Statistics.views_for(item_id: @obj_id)
      assert_equal [1, 0], Statistics.for(item_id: obj_id)
    end
  end

  test 'view counts increment correctly after key expiry' do
    freeze_time do
      previous_views = Statistics.views_for(item_id: @obj_id)

      # simulate expiring key at top of hour in order to test behaviour after ip filter rotation
      views_key = Statistics.send(:uniques_key_for, :view, @obj_id)
      # clear current timeout
      RedisClient.current.persist views_key
      # expire immediately
      RedisClient.current.pexpire views_key, -1

      # Susequent viewings outside the ip filter expiry period should now count
      Statistics.increment_view_count_for(item_id: @obj_id, ip: @test_ip)
      views =  Statistics.views_for(item_id: @obj_id)
      assert_equal previous_views + 1, views

      # a second view inside the same time period is still ignored
      Statistics.increment_view_count_for(item_id: @obj_id, ip: @test_ip)
      views = Statistics.views_for(item_id: @obj_id)
      assert_equal previous_views + 1, views
    end
  end

  test 'download counts increment correctly' do
    freeze_time do
      Statistics.increment_download_count_for(item_id: @obj_id, ip: @test_ip)
      assert_equal 1, Statistics.downloads_for(item_id: @obj_id)
      assert_equal [1, 1], Statistics.for(item_id: obj_id)

      # a second view inside the same time period is ignored
      Statistics.increment_download_count_for(item_id: @obj_id, ip: @test_ip)
      assert_equal 1, Statistics.downloads_for(item_id: @obj_id)
      assert_equal [1, 1], Statistics.for(item_id: obj_id)
      assert_equal [2, 1], Statistics.for(item_id: obj_id)
    end
  end

  test 'download counts increment correctly after key expiry' do
    freeze_time do
      previous_downloads = Statistics.downloads_for(item_id: @obj_id)
      # simulate expiring key at top of hour in order to test behaviour after ip filter rotation
      downloads_key = Statistics.send(:uniques_key_for, :download, @obj_id)
      # clear current timeout
      RedisClient.current.persist downloads_key
      # expire immediately
      RedisClient.current.pexpire downloads_key, -1

      Statistics.increment_download_count_for(item_id: @obj_id, ip: @test_ip)
      downloads = Statistics.downloads_for(item_id: @obj_id)
      assert_equal previous_downloads + 1, downloads

      # a second view inside the same time period is ignored
      Statistics.increment_download_count_for(item_id: @obj_id, ip: @test_ip)
      downloads = Statistics.downloads_for(item_id: @obj_id)
      assert_equal previous_downloads + 1, downloads
    end
  end

end
