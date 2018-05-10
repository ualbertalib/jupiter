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
  # rubocop:enable Naming/PredicateName, Lint/UnusedMethodArgument
  # TODO: implement has_many_attached
end
