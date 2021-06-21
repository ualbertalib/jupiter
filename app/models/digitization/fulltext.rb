class Digitization::Fulltext < ApplicationRecord

  belongs_to :book, class_name: 'Digitization::Book', foreign_key: :digitization_book_id, primary_key: :id,
                    inverse_of: :fulltext

  validates :text, presence: true

end
