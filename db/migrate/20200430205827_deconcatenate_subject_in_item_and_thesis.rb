class DeconcatenateSubjectInItemAndThesis < ActiveRecord::Migration[6.0]

  def change
    add_column :items, :deconcatenated_subject, :json
    add_column :theses, :deconcatenated_subject, :json

    concatenated_subject_ids = File.readlines('db/migrate/ERA_subject_issue.txt').collect(&:strip)
    report = Logger.new('log/concatenatedsubjects.log')
    (Item.all + Thesis.all).each do |item|
      item.deconcatenated_subject = if concatenated_subject_ids.include? item.id
                                      deconcatenated_subject = item.subject.map { |subject| subject.split(%r{,\s*}) }.flatten
                                      report.info("#{item.id}, \"#{item.title}\", #{item.subject}, #{deconcatenated_subject}")
                                      deconcatenated_subject
                                    else
                                      item.subject
                                    end
      item.save!
    end
  end

end
