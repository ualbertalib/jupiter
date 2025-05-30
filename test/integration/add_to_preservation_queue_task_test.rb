require 'test_helper'
require 'rake'

class AddToPreservationQueueTaskTest < ActionDispatch::IntegrationTest

  setup do
    Jupiter::Application.load_tasks if Rake::Task.tasks.empty?

    @admin = users(:user_admin)
    sign_in_as(@admin)

    Jupiter::Redis.current.del Rails.application.secrets.preservation_queue_name
  end

  test 'add all communities and collections to queue through task' do
    disable_output do
      Rake::Task['jupiter:preserve_all_collections_and_communities'].execute
      collection_and_community_count = Community.count + Collection.count

      assert_equal collection_and_community_count,
                   Jupiter::Redis.current.zcard(Rails.application.secrets.preservation_queue_name)
    end
  end

  test 'add some communities and collections to queue through task' do
    disable_output do
      travel 1.week do
        Collection.first.save!
        Community.first.save!
        Rake::Task['jupiter:preserve_all_collections_and_communities'].execute(after_date_arguments)

        # the community, collection and four items all have save actions that trigger the preservation step
        assert_equal 6, Jupiter::Redis.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  test 'no communities and collections found to queue through task' do
    disable_output do
      travel 1.week do
        Rake::Task['jupiter:preserve_all_collections_and_communities'].execute(after_date_arguments)

        assert_equal 0, Jupiter::Redis.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  test 'add all items and theses to queue through task' do
    disable_output do
      Rake::Task['jupiter:preserve_all_items_and_theses'].execute
      item_and_thesis__count = Item.count + Thesis.count

      assert_equal item_and_thesis__count,
                   Jupiter::Redis.current.zcard(Rails.application.secrets.preservation_queue_name)
    end
  end

  test 'add some items and theses to queue through task' do
    disable_output do
      travel 1.week do
        Item.first.save!
        Thesis.first.save!
        Rake::Task['jupiter:preserve_all_items_and_theses'].execute(after_date_arguments)

        assert_equal 2, Jupiter::Redis.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  test 'no items or theses found to queue through task' do
    disable_output do
      travel 1.week do
        Rake::Task['jupiter:preserve_all_items_and_theses'].execute(after_date_arguments)

        assert_equal 0, Jupiter::Redis.current.zcard(Rails.application.secrets.preservation_queue_name)
      end
    end
  end

  private

  def after_date_arguments
    Rake::TaskArguments.new([:after_date], [Date.current.to_s])
  end

end
