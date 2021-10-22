class Digitization::Image < JupiterCore::Depositable

  belongs_to :owner, class_name: 'User'

  validates :peel_image_id, uniqueness: true

end
