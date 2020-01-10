class EmbargoExpiryJob < ApplicationJob

  queue_as :default

  def perform(*_args)
    # TODO: This can be replaced with a direct query of the tables in Postgresql now that we've replaced Fedora.
    # BUT, this is working, and will continue to work, so there's no immediate need to do so.

    visibility_solr_name = Item.solr_exporter_class.solr_name_for(:visibility, role: :exact_match)
    embargo_end_date_solr_name = Item.solr_exporter_class.solr_name_for(:embargo_end_date, role: :sort)

    item_results_count, item_results, _ = JupiterCore::Search.perform_solr_query(
      q: '',
      fq: "_query_:\"{!raw f=has_model_ssim}#{Item.solr_exporter_class.indexed_has_model_name}\""\
          " AND #{visibility_solr_name}:\"#{JupiterCore::Depositable::VISIBILITY_EMBARGO}\""\
          " AND #{embargo_end_date_solr_name}:[* TO NOW]",
      rows: 10_000_000
    )

    thesis_results_count, thesis_results, _ = JupiterCore::Search.perform_solr_query(
      q: '',
      fq: "_query_:\"{!raw f=has_model_ssim}#{Thesis.solr_exporter_class.indexed_has_model_name}\""\
          " AND #{visibility_solr_name}:\"#{JupiterCore::Depositable::VISIBILITY_EMBARGO}\""\
          " AND #{embargo_end_date_solr_name}:[* TO NOW]",
      rows: 10_000_000
    )

    item_results.each do |result|
      obj = Item.find(result['id'])
      obj.visibility = obj.visibility_after_embargo
      obj.embargo_end_date = nil
      obj.visibility_after_embargo = nil
      obj.save
    end

    thesis_results.each do |result|
      obj = Thesis.find(result['id'])
      obj.visibility = obj.visibility_after_embargo
      obj.embargo_end_date = nil
      obj.visibility_after_embargo = nil
      obj.save
    end

    Rails.logger.info("Removed embargo expiry on #{item_results_count} items and #{thesis_results_count} theses")
  end

end
