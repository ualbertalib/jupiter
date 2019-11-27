Rails.application.config.after_initialize do
  Oaisys::Engine.config.oai_dc_model = Item
  Oaisys::Engine.config.oai_etdms_model = Thesis
end
