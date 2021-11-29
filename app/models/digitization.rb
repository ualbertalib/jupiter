module Digitization
  def self.table_name_prefix
    'digitization_'
  end

  # Historically peel ids have been like
  # P010572.1
  # https://github.com/ualbertalib/jupiter/issues/1769
  # so the first group is the `peel_id
  # and the second group is the `part_number`
  # TODO: missing is an optional group between the first and second for `run`
  PEEL_ID_REGEX = /P0*(\d+).(\d*)/.freeze
end
