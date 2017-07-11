# Set up the app-wide +VOCABULARY+ hash from <tt>config/vocabularies.yml</tt>
#
# See <tt>config/vocabularies.yml</tt> for detailed descriptions of the file format and expected usage
vocabs = {}

config = YAML.safe_load(File.open(Rails.root.join('config', 'vocabularies.yml')))

config.each do |vocab|
  name = vocab['vocabulary'].to_sym
  vocabs[name] = Class.new(RDF::Vocabulary(vocab['schema'])) do
    vocab['terms'].each do |t|
      term t.to_sym
    end
  end
end

VOCABULARY = vocabs.freeze
