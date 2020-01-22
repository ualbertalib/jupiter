Rails.application.config.after_initialize do
  Oaisys::Engine.config.oai_dc_model = Item
  Oaisys::Engine.config.oai_etdms_model = Thesis
  Oaisys::Engine.config.top_level_sets_model = Community
  Oaisys::Engine.config.set_model = Collection
  Oaisys::Engine.config.redis_url = Rails.application.secrets.redis_url
  Oaisys::Engine.config.redis = Oaisys::RedisConnection.new
end
