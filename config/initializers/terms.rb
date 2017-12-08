# Set up the app-wide +VOCABULARY+ hash from <tt>config/terms.yml</tt>
#
# See <tt>config/terms.yml</tt> for detailed descriptions of the file format and expected usage
terms = {}

config = YAML.safe_load(File.open(Rails.root.join('config', 'terms.yml')))

config.each do |vocab|
  name = vocab['vocabulary'].to_sym
  terms[name] = Class.new(RDF::Vocabulary(vocab['schema'])) do
    vocab['terms'].each do |t|
      term t.to_sym
    end
  end
end

TERMS = terms.freeze
