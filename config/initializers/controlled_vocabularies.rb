# Set up the app-wide +ControlledVocabulary+ singleton from <tt>vocab/controlled_vocabularies/*</tt>.
#
# Vocabularies come in two flavors – i18n and raw. 
#
# i18n vocabs map individual URIs in the vocabulary to Ruby symbols. The symbols can later be used as keys into the
# Rails' i18n machinery in order to generate a human-readable localized representation of the term. This is intended
# for URIs like http://terms.library.ualberta.ca/private, which may be presented to a User as "private" in English
# or "confidentiel" in French (or whatever, I don't speak enough French to vouch that that's the correct translation.
# This is just an example)
#
# raw vocabs map individual URIs in the vocabulary directly to a human-readable representation. This is intended for 
# 'concept' URIs like http://id.loc.gov/authorities/names/n79007225, which map to "Edmonton (Alta.)", which is not
# a translatable name in any meaningful sense. It's anticipated that these vocabulary sets will be generated
# automatically, which makes the generation of intermediary symbols cumbersome, and the resulting flood of 
# not-really-translated i18n entries undesirable.
#
# i18n vocabs are distinguished by the file extension foo.i18n.yml. raw vocabs are distinguished by the file extension
# foo.raw.yml.
#
# All vocabularies are stored in filesystem paths of the form 
# +vocab/controlled_vocabularies/<vocabularies>/foo.{raw,i18n}.yml+, where foo becomes the vocabulary's name and 
# <vocabularies> the vocabularies the vocab must be looked up in. All vocabularies are read into memory at application
# boot, to avoid filesystem overhead during requests.
#
# Note that URI->human-readable translations happen in the hot loop of facet result rendering, so any future
# refactoring happening here should try to make this as cheap as humanly possible, potentially at the cost
# of increasing resident memory.

controlled_vocabularies = {}

namespaces = Dir.glob(Rails.root.join('config/controlled_vocabularies/**'))

namespaces.each do |dir|
  namespace = File.basename(dir).to_sym
  vocabularies = {}

  i18n_vocabularies = Dir.glob("#{dir}/*.i18n.yml")

  i18n_vocabularies.each do |file|
  
    vocab = YAML.safe_load(File.open(file)).deep_symbolize_keys.freeze
    raise VocabularyInvalidError, 'There should be only one top-level vocabulary name key' unless vocab.keys.count == 1
    
    vocab_name = vocab.keys.first
    raise VocabularyInvalidError, 'Vocab #{vocab_name} already exists!' if vocabularies.key?(vocab_name)

    vocab_items = vocab[vocab_name]
    raise VocabularyInvalidError, 'Vocab must contain key-value mappings' unless vocab_items.is_a?(Hash)

    vocabularies[vocab_name] = {
      is_i18n: true,
      data: nil
    }
    
    uri_mappings = vocab_items.invert

    # For i18n vocabs, we create a simple object whose methods are the symbols from the file, which
    # return the corresponding URI values.
    #
    # We additionally extend the object with a method for mapping URIs back to symbols, and extend `method_missing`
    # to provide better error messages.

   vocabularies[vocab_name][:data] = OpenStruct.new(vocab_items).tap do |vocab|
      vocab.define_singleton_method(:from_uri) do |uri|
        uri_mappings[uri]
      end
      vocab.define_singleton_method(:method_missing) do |name, *args, &block|
        super(name, *args, &block) || (raise JupiterCore::VocabularyMissingError, "Unknown #{vocab_name} key: #{name}")
      end
    end
  end

  controlled_vocabularies[namespace] = vocabularies
end
binding.pry

ControlledVocabulary = Class.new do
  binding.pry

  CONTROLLED_VOCABULARIES = controlled_vocabularies.freeze

  def self.lookup(namespace:, vocab:, symbol:)
    raise ArgumentError, "Namespace not found: #{namespace}" unless CONTROLLED_VOCABULARIES.key?(namespace)
    raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES[namespace].key?(vocab)

    CONTROLLED_VOCABULARIES.dig(namespace, vocab, :data, symbol)
  end

  def self.is_i18n?(namespace:, vocab:)
    raise ArgumentError, "Namespace not found: #{namespace}" unless CONTROLLED_VOCABULARIES.key?(namespace)
    raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES[namespace].key?(vocab)
   
    CONTROLLED_VOCABULARIES.dig(namespace, vocab, :is_i18n)
  end

  CONTROLLED_VOCABULARIES.each do |namespace, vocabs|
    # We create a simple responder that has methods for each vocabulary in the namespace
    namespace_responder = Class.new do
      vocabs.each do |vocab_name, values|
        define_singleton_method vocab_name do
          values[:data]
        end
      end
    end

    # And then we define a method on +ControlledVocabulary+ for each namespace.
    # This gives us a nicer lookup DSL: +ControlledVocabulary.era.license.blah+ vs 
    # +ControlledVocabulary.lookup(:era, :license).blah+. 
    #
    # This is also _faster_, because lookups
    # that call the methods don't need to hash the keys once to check if they exist for error message purposes
    # prior to hashing it again for the lookup.
    define_singleton_method namespace do
      namespace_responder
    end
  end
end