class Statistics

  def self.increment_view_count_for(item_id:, ip:)
    increment_action_counter(action: :view, id: item_id, ip: ip)
  end

  def self.increment_download_count_for(item_id:, ip:)
    increment_action_counter(action: :download, id: item_id, ip: ip)
  end

  def self.views_for(item_id:)
    Redis.current.get(counter_key_for(:view, item_id)).to_i || 0
  end

  def self.downloads_for(item_id:)
    Redis.current.get(counter_key_for(:download, item_id)).to_i || 0
  end

  # Conveinience method for fetching all counts for a given item. The expectation is that you probably want to
  # destructure the results, eg)
  #
  #    @views, @downloads = Statistics.for(item.id)
  def self.for(item_id:)
    [views_for(item_id: item_id), downloads_for(item_id: item_id)]
  end

  class << self

    private

    def increment_action_counter(action:, id:, ip:)
      uniques_filter_key = uniques_key_for(action, id)
      counter_key = counter_key_for(action, id)

      # based on some experimentation, key sizes for pfadd seems slightly more space and time efficient
      # than a scored set approach, but if imprecision becomes an issue we could revisit that as an alternative
      # at the cost of some space if items get "hot"
      is_new_visit = Redis.current.pfadd(uniques_filter_key, ip)

      # ip filters reset at the top of the hour, so if the key was freshly (re-)created we need to set its TTL
      Redis.current.expireat(uniques_filter_key, Time.current.end_of_hour.to_i)
      return unless is_new_visit

      Redis.current.incr(counter_key)
    end

    def uniques_key_for(action, id)
      "#{Rails.configuration.redis_key_prefix}uniquehll.#{action}.#{id}"
    end

    def counter_key_for(action, id)
      "#{Rails.configuration.redis_key_prefix}counter.#{action}.#{id}"
    end

  end

end
