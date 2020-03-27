class CollectionPolicy < DepositablePolicy

  def index?
    true
  end

  # This policy is used for the AIP V1 API. Pundit does not allow use of
  # namespaces

  def show_collection?
    system? || admin?
  end

end
