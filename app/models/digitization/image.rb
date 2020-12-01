class Digitization::Image < ApplicationRecord

  validates :peel_image_id, uniqueness: true

end
