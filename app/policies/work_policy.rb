class WorkPolicy < ApplicationPolicy

  def index?
    true
  end

  def create?
    owned? || admin?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def owned?
    user.present?
    # TODO: Currently record (work) has no relationship to a user/creator
    # record && user && record.creator == user.email
  end

  def permitted_attributes
    [:visibility,
      :owner,
      :title,
      :subject,
      :creator,
      :contributor,
      :description,
      :publisher,
      :date_created,
      :language,
      :doi,
      :member_of_paths,
      :embargo_end_date
    ]
  end

  class Scope < ApplicationPolicy::Scope

    def resolve
      # eventually we only want to show public works
      # if user.admin?
      scope.all
      # else
      #   scope.where(private: false)
      # end
    end

  end

end
