class Digitization::Map < ApplicationRecord

  validates :peel_map_id, uniqueness: true

end
