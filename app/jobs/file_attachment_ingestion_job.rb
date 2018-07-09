class FileAttachmentIngestionJob < ApplicationJob

  queue_as :default

  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find(attachment_id)

    # occasionally these things get picked up again if the previous job errored out
    return if attachment.fileset_uuid.present?

    item = attachment.record.owner

    path = ActiveStorage::Blob.service.send(:path_for, attachment.blob.key)
    original_filename = attachment.blob.filename.to_s
    File.open(path) do |file|
      # We're exploiting the fact that Hydra-Works calls original_filename on objects passed to it, if they
      # respond to that method, in preference to looking at the final portion of the file path, which,
      # because we fished this out of ActiveStorage, is just a hash. In this way we present Fedora with the original
      # file name of the object and not a hashed or otherwise modified version temporarily created during ingest
      file.send(:define_singleton_method, :original_filename, -> { original_filename })

      item.unlock_and_fetch_ldp_object do |unlocked_obj|
        FileSet.new_locked_ldp_object.unlock_and_fetch_ldp_object do |unlocked_fileset|
          unlocked_fileset.owner = unlocked_obj.owner
          unlocked_fileset.visibility = unlocked_obj.visibility

          Hydra::Works::AddFileToFileSet.call(unlocked_fileset, file, :original_file,
                                              update_existing: false, versioning: false)
          unlocked_fileset.member_of_collections += [unlocked_obj]
          # Temporarily cache the file name for storing in Solr
          # if the file was uploaded, it responds to +original_filename+
          # if it's a Ruby File object, it has a +basename+. This distinction seems arbitrary.
          unlocked_fileset.contained_filename = if file.respond_to?(:original_filename)
                                                  file.original_filename
                                                else
                                                  File.basename(file)
                                                end
          # Store file properties in the format required by the sitemap
          # for quick and easy retrieval -- nobody wants to wait 36hrs for this!
          escaped_path = CGI.escape_html(Rails.application.routes.url_helpers.url_for(
                                           controller: :downloads,
                                           action: :view,
                                           id: unlocked_obj.id,
                                           file_set_id: unlocked_fileset.id,
                                           file_name: unlocked_fileset.contained_filename,
                                           only_path: true
                                         ))
          unlocked_fileset.sitemap_link = "<rs:ln \
  href=\"#{escaped_path}\" \
  rel=\"content\" \
  hash=\"#{unlocked_fileset.original_file.checksum.algorithm.downcase}:"\
  "#{unlocked_fileset.original_file.checksum.value}\" \
  length=\"#{unlocked_fileset.original_file.size}\" \
  type=\"#{unlocked_fileset.original_file.mime_type}\"\
  />"
          unlocked_fileset.save!
          attachment.fileset_uuid = unlocked_fileset.id
          attachment.save

          if Rails.configuration.run_fits_characterization
            Hydra::Works::CharacterizationService.run(unlocked_fileset.original_file)
            unlocked_fileset.original_file.save
          end

          # Appending to +ordered_members+ results in a scrambled set of proxy relations for reasons probably having
          # to do with ActiveFedora bugginess. We therefore append the new fileset to the existing ones in a new array
          # and overrite the entire ordered_members value.
          #
          # HOWEVER this causes the "original filesets" be retrieved and re-saved (pointlessly) by AF,
          # and without connecting them to owning LockedLDP instances (which they need to solrize properly)
          # this causes the save to crash. So we must first iterate through each original fileset and instantiate
          # a new LockedLdpObject wrapper to connect them with via +LockedLdpObject#reconnect_owning_jupiter_object!+
          original_filesets = unlocked_obj.ordered_members.to_a || []
          original_filesets.each { |ofs| JupiterCore::LockedLdpObject.reconnect_owning_jupiter_object!(ofs) }
          unlocked_obj.ordered_members = (original_filesets + [unlocked_fileset])

          unlocked_obj.save!
        end
      end
    end
  end

end
