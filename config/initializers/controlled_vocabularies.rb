# Set up the app-wide +CONTROLLED_VOCABULARY+ hash from <tt>config/controlled_vocabularies/*</tt>
controlled_vocabularies = {}

config_files = Dir.glob(Rails.root.join('config', 'controlled_vocabularies', '*.yml'))

config_files.each do |file|
  config = YAML.safe_load(File.open(file)).deep_symbolize_keys.freeze
  controlled_vocabularies.merge!(config)
end

config_files.each do |file|
  config = YAML.safe_load(File.open(file)).deep_symbolize_keys.freeze
  raise VocabularyInvalidError, 'There should be only one top-level vocabulary name key' unless config.keys.count == 1
  vocab_name = config.keys.first
  uri_mappings = config[vocab_name].invert
  controlled_vocabularies[vocab_name] = OpenStruct.new(config[vocab_name]).tap do |vocab|
    vocab.define_singleton_method(:from_uri) do |uri|
      uri_mappings[uri]
    end
    vocab.define_singleton_method(:method_missing) do |name, *args, &block|
      super(name, *args, &block) || (raise "Unknown #{vocab_name} key: #{name}")
    end
  end
end

CONTROLLED_VOCABULARIES = controlled_vocabularies.freeze
