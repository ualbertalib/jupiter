class MonthlyChangesReportJob < ApplicationJob

  queue_as :default

  def perform
    time = Time.now
    CSV.open("#{time.year}_#{time.month}_changes.csv", 'wb') do |csv|
      csv << ['item type', 'item id', 'item changed at']
      PaperTrail::Version.where(created_at: time.prev_month..).each do |item|
        csv << [item.item_type, item.item_id, item.created_at, item.event]
      end
    end
  end

end
