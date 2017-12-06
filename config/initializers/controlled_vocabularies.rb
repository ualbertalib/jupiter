# Set up the app-wide +CONTROLLED_VOCABULARY+ hash from <tt>config/controlled_vocabularies/*</tt>
controlled_vocabularies = {}

config_files = Dir.glob(Rails.root.join('config', 'controlled_vocabularies', '*.yml'))

config_files.each do |file|
  config = YAML.safe_load(File.open(file)).deep_symbolize_keys.freeze
  controlled_vocabularies.merge!(config)
end

# Add some helpers so that we can easily get a URI from a code.
controlled_vocabularies.each do |name, vocabulary|
  vocabulary.instance_variable_set(:@vocabulary, name)
  # URI --> [text|code] functions
  def vocabulary.uri_to_code(uri)
    each do |term|
      return term[:code] if term[:uri] == uri
    end
    raise ArgumentError, "#{uri} not found in controlled vocabulary: #{@vocabulary}"
  end

  def vocabulary.code_to_text(code)
    I18n.t("controlled_vocabularies.#{@vocabulary}.#{code}")
  end

  def vocabulary.uri_to_text(uri)
    code_to_text(uri_to_code(uri))
  end

  vocabulary.each do |term|
    next unless term.key?(:code) && term.key?(:uri)
    # Code --> URI methods
    controlled_vocabularies[name].define_singleton_method(term[:code]) do
      return term[:uri]
    end
  end
end

CONTROLLED_VOCABULARIES = controlled_vocabularies.freeze
