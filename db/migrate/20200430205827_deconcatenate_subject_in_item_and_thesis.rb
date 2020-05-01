class DeconcatenateSubjectInItemAndThesis < ActiveRecord::Migration[6.0]

  def change
    add_column :items, :deconcatenated_subject, :json
    add_column :theses, :deconcatenated_subject, :json

    @concatenated_subject_ids = File.readlines(Rails.root.join('ERA_subject_issue.txt')).collect(&:strip)
    @report = Logger.new(Rails.root.join('log/concatenated_subjects.log'))

    Item.find_each do |item|
      item.deconcatenated_subject = deconcatenated_subject(item)
      item.save!
    end

    Thesis.find_each do |item|
      item.deconcatenated_subject = deconcatenated_subject(item)
      item.save!
    end
  end

  def deconcatenated_subject(item)
    return item.subject unless @concatenated_subject_ids.include? item.id

    deconcatenated_subject = item.subject.map { |subject| subject.split(%r{,\s*}) }.flatten
    @report.info(
      "id: #{item.id}, title: \"#{item.title}\", subject: #{item.subject},"\
      " deconcatenated subject: #{deconcatenated_subject}"
    )

    deconcatenated_subject
  end

end
