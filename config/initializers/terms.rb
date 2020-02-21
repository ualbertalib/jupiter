# Set up the app-wide +VOCABULARY+ hash from <tt>config/terms.yml</tt>
#
# See <tt>config/terms.yml</tt> for detailed descriptions of the file format and expected usage
terms = {}

config = YAML.safe_load(File.open(Rails.root.join('config/terms.yml')))

config.each do |vocab|
  name = vocab['vocabulary'].to_sym
  rdf_class = Class.new(RDF::StrictVocabulary(vocab['schema'])) do
    vocab['terms'].each_value do |value|
      term value.to_sym
    end
  end

  terms[name] = Object.new.tap do |obj|
    obj.define_singleton_method :schema do
      vocab['schema']
    end
    obj.define_singleton_method :rdf_class do
      rdf_class
    end
    vocab['terms'].each do |key, value|
      obj.define_singleton_method key.to_sym do
        rdf_class.send(value.to_sym)
      end
    end
  end
end

TERMS = terms.freeze
