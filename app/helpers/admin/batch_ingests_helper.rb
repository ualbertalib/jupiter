module Admin::BatchIngestsHelper
  def badge_status_color(status)
    case status
    when 'failed'
      'badge-danger'
    when 'completed'
      'badge-success'
    else
      'badge-secondary'
    end
  end
end
