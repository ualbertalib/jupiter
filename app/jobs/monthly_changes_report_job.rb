class MonthlyChangesReportJob < ApplicationJob

  queue_as :default

  def perform(date)
    CSV.open("#{date.year}_#{date.month}_changes.csv", 'wb') do |csv|
      csv << ['item type', 'item id', 'item changed at']
      PaperTrail::Version.where(created_at: date..).find_each do |item|
        csv << [item.item_type, item.item_id, item.created_at, item.event]
      end
    end

    i = Item.updated_on_or_after(date).count
    t = Thesis.updated_on_or_after(date).count
    cl = Collection.updated_on_or_after(date).count
    cm = Community.updated_on_or_after(date).count
    summary = "#{i} items, #{t} theses, #{cl} collections and #{cm} communities were created or modified."

    File.write("#{date.year}_#{date.month}_summary.txt", summary)
  end

end
