module Digitization
  PEEL_ID_REGEX = /P0*(\d+).(\d*)/.freeze

  def self.table_name_prefix
    'digitization_'
  end
end
