class Digitization::Map < JupiterCore::Depositable

  belongs_to :owner, class_name: 'User'

  validates :peel_map_id, uniqueness: true

end
