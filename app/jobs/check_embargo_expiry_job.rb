class CheckEmbargoExpiryJob < ApplicationJob

  queue_as :default

  def perform(*args)
    # TODO: Should be a better way to query solr?
    # Can't do date logic like this for Item.where(visibility: ItemProperties::VISIBILITY_EMBARGO, embargo_end_date: [* TO NOW])
    # And faceted_search has visibility based on current_user
    # So dropped down to perform_solr_query to get what I need

    visibility_solr_name = Item.solr_name_for(:visibility, role: :exact_match)
    embargo_end_date_solr_name = Item.solr_name_for(:embargo_end_date, role: :sort)

    # TODO: Should be able to get both items and theses together with one solr query?
    # But doesn't seem to like combining them
    item_results_count, item_results, _ = JupiterCore::Search.perform_solr_query({
      q: "",
      :fq => "_query_:\"{!raw f=has_model_ssim}#{Item.af_parent_class}\" AND #{visibility_solr_name}:\"#{ItemProperties::VISIBILITY_EMBARGO}\" AND #{embargo_end_date_solr_name}:[* TO NOW]",
      rows: 10000000
    })

    thesis_results_count, thesis_results, _ = JupiterCore::Search.perform_solr_query({
      q: "",
      :fq => "_query_:\"{!raw f=has_model_ssim}#{Thesis.af_parent_class}\" AND #{visibility_solr_name}:\"#{ItemProperties::VISIBILITY_EMBARGO}\" AND #{embargo_end_date_solr_name}:[* TO NOW]",
      rows: 10000000
    })

    (item_results + thesis_results).each do |result|
      obj = JupiterCore::LockedLdpObject.reify_solr_doc(result)
      obj.unlock_and_fetch_ldp_object do |item|
        item.visibility = item.visibility_after_embargo
        item.embargo_end_date = nil
        item.visibility_after_embargo = nil
        item.save
      end
    end

    Rails.logger.info("Removed embargo expiry on #{item_results_count} items and #{thesis_results_count} theses")
  end

end
