module ItemsHelper
  def creator_search_path(creator)
    # TODO: the search path may need to be revisited
    search_path(search: "creator_tesim:#{creator}")
  end
end
