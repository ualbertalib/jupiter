class FileSetsController < ApplicationController

  before_action :load_and_authorize_fileset

  # TODO: expand to handle derivatives
  def show
    stream_from_fedora
  end

  def download
    stream_from_fedora(disposition: 'attachment', content_type: 'application/octet-stream')
  end

  private

  def load_and_authorize_fileset
    @file_name = params[:file_name]
    @file_set = FileSet.find(params[:id])
    @owning_item = Item.find(@file_set.item)
    return render status: :not_found if @file_set.blank?
    return render status: :not_found unless @file_name == @file_set.contained_filename

    authorize @owning_item, :download?
  end

  def stream_from_fedora(disposition: nil, content_type: nil)
    disposition ||= 'inline'
    content_type ||= @file_set.original_mime_type
    @file_set.unlock_and_fetch_ldp_object do |unlocked_fileset|
      uri = URI(unlocked_fileset.original_file.uri)
      request = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      send_data response.body, filename: @file_name, disposition: disposition, content_type: content_type
    end
  end

end
