# Set up the app-wide +CONTROLLED_VOCABULARY+ hash from <tt>config/controlled_vocabularies/*</tt>
controlled_vocabularies = {}

config_files = Dir.glob(Rails.root.join('config', 'controlled_vocabularies', '*.yml'))

config_files.each do |file|
  config = YAML.safe_load(File.open(file)).deep_symbolize_keys.freeze
  controlled_vocabularies.merge!(config)
end

CONTROLLED_VOCABULARIES = controlled_vocabularies.freeze
