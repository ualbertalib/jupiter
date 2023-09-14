require 'test_helper'
require 'rake'
require 'application_system_test_case'

class AddToPreservationQueueTaskTest < ApplicationSystemTestCase

  setup do
    Jupiter::Application.load_tasks if Rake::Task.tasks.empty?

    @admin = users(:user_admin)
    login_user(@admin)

    RedisClient.current.del Rails.application.secrets.preservation_queue_name
  end

  teardown do
    logout_user
  end

  test 'add all communities and collections to queue through task' do
    disable_output do
      Rake::Task['jupiter:preserve_all_collections_and_communities'].execute
      collection_and_community_count = Community.count + Collection.count

      assert_equal collection_and_community_count,
                   RedisClient.current.zcard(Rails.application.secrets.preservation_queue_name)
    end
  end

  test 'add some communities and collections to queue through task' do
    disable_output do
      travel 1.week do
        Collection.first.save!
        Community.first.save!
        Rake::Task['jupiter:preserve_all_collections_and_communities'].execute(after_date_arguments)

        assert_equal 2, RedisClient.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  test 'no communities and collections found to queue through task' do
    disable_output do
      travel 1.week do
        Rake::Task['jupiter:preserve_all_collections_and_communities'].execute(after_date_arguments)

        assert_equal 0, RedisClient.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  test 'add all items and theses to queue through task' do
    disable_output do
      Rake::Task['jupiter:preserve_all_items_and_theses'].execute
      item_and_thesis__count = Item.count + Thesis.count

      assert_equal item_and_thesis__count,
                   RedisClient.current.zcard(Rails.application.secrets.preservation_queue_name)
    end
  end

  test 'add some items and theses to queue through task' do
    disable_output do
      travel 1.week do
        Item.first.save!
        Thesis.first.save!
        Rake::Task['jupiter:preserve_all_items_and_theses'].execute(after_date_arguments)

        assert_equal 2, RedisClient.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  test 'no items or theses found to queue through task' do
    disable_output do
      travel 1.week do
        Rake::Task['jupiter:preserve_all_items_and_theses'].execute(after_date_arguments)

        assert_equal 0, RedisClient.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  private

  def after_date_arguments
    Rake::TaskArguments.new([:after_date], [Date.current.to_s])
  end

end
