module JupiterCore::ActiveStorageMacros
  # https://github.com/rails/rails/blob/master/activestorage/lib/active_storage/attached/macros.rb but for
  # non-ActiveRecord purposes

  # rubocop:disable Naming/PredicateName, Lint/UnusedMethodArgument
  def has_one_attached(name, dependent: false)
    class_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{name}
        @active_storage_attached_#{name} ||= #{name}_attachment_shim&.shimmed_file
      end
      def #{name}=(attachable)
        #{name}.attach(attachable)
      end
      def #{name}_attachment
        #{name}_attachment_shim&.shimmed_file_attachment
      end
      def #{name}_blob
        #{name}_attachment.blob
      end
      def #{name}_attachment_shim
        return unless id.present?
        @active_storage_shimmed_#{name} ||= begin
          shim = JupiterCore::AttachmentShim.with_attached_shimmed_file.where(owner_global_id: to_global_id.to_s, name: "#{name}").first
          shim ||= JupiterCore::AttachmentShim.create!(owner_global_id: to_global_id.to_s, name: "#{name}")
        end
      end
    CODE

    derived_af_class.class_eval do
      # NOTE: don't change this to after_destroy. It doesn't run. Presumably just another case of AF failing at its
      # basic job.
      before_destroy { public_send(:"#{name}_attachment_shim").destroy }
    end
  end

  def has_many_attached(name, dependent: false)
    class_eval <<-CODE, __FILE__, __LINE__ + 1
      def #{name}
        @active_storage_attached_#{name} ||= #{name}_attachment_shim&.shimmed_files
      end
      def #{name}=(attachables)
        #{name}.attach(attachables)
      end
      def #{name}_attachments
        #{name}_attachment_shim&.shimmed_files_attachments
      end
      def #{name}_blobs
        #{name}_attachments.blobs
      end
      def #{name}_attachment_shim
        return unless id.present?
        @active_storage_shimmed_#{name} ||= begin
          shim = JupiterCore::AttachmentShim.with_attached_shimmed_files.where(owner_global_id: to_global_id.to_s, name: "#{name}").first
          shim ||= JupiterCore::AttachmentShim.create!(owner_global_id: to_global_id.to_s, name: "#{name}")
        end
      end
    CODE

    derived_af_class.class_eval do
      # NOTE: don't change this to after_destroy. It doesn't run. Presumably just another case of AF failing at its
      # basic job.
      before_destroy { public_send(:"#{name}_attachment_shim").destroy }
    end
  end
  # rubocop:enable Naming/PredicateName, Lint/UnusedMethodArgument

  # HACK: Messing with Rails internals for fun and profit
  # we're accessing the raw ActiveStorage local drive service internals to avoid the overhead of pulling temp files
  # out.
  def file_path_for(file)
    ActiveStorage::Blob.service.send(:path_for, file.key)
  end

  # Fedora file handling
  # Convert ActiveStorage objects into File objects so we can deposit them into fedora
  def map_activestorage_files_as_file_objects
    files.map do |file|
      path = file_path_for(file)
      original_filename = file.filename.to_s
      File.open(path) do |f|
        # We're exploiting the fact that Hydra-Works calls original_filename on objects passed to it, if they
        # respond to that method, in preference to looking at the final portion of the file path, which,
        # because we fished this out of ActiveStorage, is just a hash. In this way we present Fedora with the original
        # file name of the object and not a hashed or otherwise modified version temporarily created during ingest
        f.send(:define_singleton_method, :original_filename, -> { original_filename })
        yield f
      end
    end
  end
end
