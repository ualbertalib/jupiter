class RelatedObject < Hydra::Works::Work

  include Hydra::Works::WorkBehavior
  property :related_to, predicate: ::Hydra::PCDM::Vocab::PCDMTerms.hasRelatedObject, multiple: false
  validates :related_to, presence: true

  def add_file(file)
    return if file.nil?
    save! if id.nil?

    Hydra::Works::FileSet.new do |fileset|
      Hydra::Works::AddFileToFileSet.call(fileset, file, :original_file,
                                          update_existing: false, versioning: false)
      fileset.member_of_collections += [self]
      fileset.save!
      self.members += [fileset]
    end
  end

end
