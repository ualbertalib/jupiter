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
# +config/controlled_vocabularies/<vocabularies>/foo.{raw,i18n}.yml+, where foo becomes the vocabulary's name and
# <vocabularies> the vocabularies the vocab must be looked up in. All vocabularies are read into memory at application
# boot, to avoid filesystem overhead during requests.
#
# Note that URI->human-readable translations happen in the hot loop of facet result rendering, so any future
# refactoring happening here should try to make this as cheap as humanly possible, potentially at the cost
# of increasing resident memory.
#
# There are two methods for looking up values and URIs:
#
# 1. Dynamically. When looking up a URI this returns both the value it maps to and a boolean indicating whether or
#    not the value returned is an i18n translatable symbol or not (if not, it's a raw value)
#       ControlledVocabulary.value_from_uri(namespace: :digitization, vocab: :subject, uri: "http://id.loc.gov/authorities/names/n79007225")
#        => ["Edmonton (Alta.)", false]
#       ControlledVocabulary.uri_from_value(namespace: :digitization, vocab: :subject, value: "Edmonton (Alta.)")
#        => "http://id.loc.gov/authorities/names/n79007225"
#
# 2. When you know the namespace and vocab at the time you're writing the code. This presumes that because you know
#    the vocab you're working with, you already know whether or not it's an i18n vocabulary, and therefore it only
#    returns the value or URI in question:
#       uri = "http://id.loc.gov/authorities/names/n79007225"
#       ControlledVocabulary.digitization.subject.from_uri(uri)
#        => "Edmonton (Alta.)"
#       ControlledVocabulary.digitization.subject.from_value("Edmonton (Alta.)")
#        => "http://id.loc.gov/authorities/names/n79007225"
#
#   This also allows directly looking up URIs that map to i18n symbols by using the i18n symbol as a method, eg)
#       ControlledVocabulary.era.language.english
#        => "http://id.loc.gov/vocabulary/iso639-2/eng"
#
#
# I can't believe rubocop is so dumb it doesn't know these are required args for any method_missing override, method OR block.
# It also gets CONSTANT scope definitions wrong in self.methods in Class.new position wrong, and doesn't get that
# you don't want respond_to_missing if you're just raising a more-specific error in method_missing, so I'm shutting all these off for
# this file. Garbage effort, rubocop.
#
# rubocop:disable Lint/UnusedMethodArgument, Style/MissingRespondToMissing, Lint/UnusedBlockArgument, Lint/ConstantDefinitionInBlock

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
    raise VocabularyInvalidError, "Vocab #{vocab_name} already exists!" if vocabularies.key?(vocab_name)

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

    vocabularies[vocab_name][:data] = OpenStruct.new(vocab_items).tap do |vocab_responder|
      vocab_responder.define_singleton_method(:from_uri) do |uri|
        uri_mappings[uri]
      end
      vocab_responder.define_singleton_method(:from_value) do |value|
        vocab_items[value.to_sym]
      end
      vocab_responder.define_singleton_method(:method_missing) do |name, *args, &block|
        super(name, *args, &block) || (raise JupiterCore::VocabularyMissingError, "Unknown #{vocab_name} key: #{name}")
      end
    end
  end

  raw_vocabularies = Dir.glob("#{dir}/*.raw.yml")

  raw_vocabularies.each do |file|
    vocab = YAML.safe_load(File.open(file)).freeze
    raise VocabularyInvalidError, 'There should be only one top-level vocabulary name key' unless vocab.keys.count == 1

    vocab_name = vocab.keys.first
    raise VocabularyInvalidError, "Vocab #{vocab_name} already exists!" if vocabularies.key?(vocab_name)

    vocab_items = vocab[vocab_name]
    raise VocabularyInvalidError, 'Vocab must contain key-value mappings' unless vocab_items.is_a?(Hash)

    vocab_name = vocab_name.to_sym
    vocabularies[vocab_name] = {
      is_i18n: false,
      data: nil
    }

    uri_mappings = vocab_items.invert

    # For raw vocabs there is no method lookup, only from_uri and from_value
    vocabularies[vocab_name][:data] = Class.new do
      define_singleton_method :from_uri do |uri|
        uri_mappings[uri]
      end

      define_singleton_method :from_value do |value|
        vocab_items[value]
      end
    end
  end

  controlled_vocabularies[namespace] = vocabularies
end

ControlledVocabulary = Class.new do
  CONTROLLED_VOCABULARIES = controlled_vocabularies.freeze

  def self.lookup_vocab(namespace:, vocab:)
    # doing this backwards of normal guard clauses so that we only pay for the extra hashing of namespace and vocab
    # keys to check for their existence IF the call to dig returns nil. This way, the happy path is a bit faster
    # in the hot loop of URI mapping during facet rendering

    CONTROLLED_VOCABULARIES.dig(namespace, vocab) || begin
      raise ArgumentError, "Namespace not found: #{namespace}" unless CONTROLLED_VOCABULARIES.key?(namespace)
      raise ArgumentError, "Vocabulary not found: #{vocab}" unless CONTROLLED_VOCABULARIES[namespace].key?(vocab)
    end
  end

  def self.uri_from_value(namespace:, vocab:, value:)
    lookup_vocab(namespace: namespace, vocab: vocab)[:data].from_value(value)
  end

  def self.value_from_uri(namespace:, vocab:, uri:)
    vocab = lookup_vocab(namespace: namespace, vocab: vocab)

    [vocab[:data].from_uri(uri), vocab[:is_i18n]]
  end

  def self.i18n?(namespace:, vocab:)
    lookup_vocab(namespace: namespace, vocab: vocab)[:is_i18n]
  end

  def self.method_missing(name, *args, &block)
    raise JupiterCore::VocabularyMissingError, "Unknown namespace #{name}"
  end

  CONTROLLED_VOCABULARIES.each do |namespace, vocabs|
    # We create a simple responder that has methods for each vocabulary in the namespace
    namespace_responder = Class.new do
      vocabs.each do |vocab_name, values|
        define_singleton_method vocab_name do
          values[:data]
        end
      end

      define_singleton_method(:method_missing) do |name, *args, &block|
        raise JupiterCore::VocabularyMissingError, "Unknown vocabulary #{name} for namespace #{namespace}"
      end
    end

    # And then we define a method on +ControlledVocabulary+ for each namespace which returns the responder.
    # This gives us a nicer lookup DSL: +ControlledVocabulary.era.license.blah+ vs
    # +ControlledVocabulary.lookup_vocab(namespace: :era, vocab: :license).blah+.
    define_singleton_method namespace do
      namespace_responder
    end
  end
end

# rubocop:enable Lint/UnusedMethodArgument, Style/MissingRespondToMissing, Lint/UnusedBlockArgument, Lint/ConstantDefinitionInBlock
