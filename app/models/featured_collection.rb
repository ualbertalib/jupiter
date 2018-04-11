class FeaturedCollection

  # TODO: The longer term plan is to make the front page panels dynamically controllable by admins,
  # so this acts as a faux-model in anticipation of moving this information into a datastore.
  # In the short-term we're hardcoding the panel links to their respective communities & collection ids
  # in Production. It's ugly.
  AFNS_COMMUNITY = '30ae3d88-e1d1-49d8-9e8d-897bdcf202ee'.freeze
  AFNS_JOURNALS_COLLECTION = '7b8516f0-7642-4c93-a20e-02ce4e7b0815'.freeze

  RESEARCH_IMAGES_COMMUNITY = 'e14a6354-b557-4a15-8e99-70ad237be121'.freeze

  GRAD_STUDIES_COMMUNITY = 'db9a4e71-f809-4385-a274-048f28eb6814'.freeze
  THESIS_COLLECTION = 'f42f3da6-00c3-4581-b785-63725c33c7ce'.freeze

  OSRIN_COMMUNITY = 'e4fdd15f-c21d-4612-a2f7-bfec3fdfc1de'.freeze

  def self.afns_community
    AFNS_COMMUNITY
  end

  def self.afns_journals_collection
    AFNS_JOURNALS_COLLECTION
  end

  def self.osrin_community
    OSRIN_COMMUNITY
  end

  def self.research_images_community
    RESEARCH_IMAGES_COMMUNITY
  end

  def self.grad_studies_community
    GRAD_STUDIES_COMMUNITY
  end

  def self.thesis_collection
    THESIS_COLLECTION
  end

end
