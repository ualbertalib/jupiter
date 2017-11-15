class FileSetsController < ApplicationController

  # TODO: expand to handle derivatives
  def view_original
    stream_from_fedora
  end

  def download_original
    stream_from_fedora(disposition: 'attachment', content_type: 'application/octet-stream')
  end

  private

  def stream_from_fedora(disposition: nil, content_type: nil)
    @file_set = FileSet.find(params[:id])
    return render status: :not_found unless @file_set.present?
    authorize @file_set.item, :show?

    disposition ||= 'inline'
    content_type ||= @file_set.original_mime_type

    @file_name = params[:file_name]
    return render status: :not_found unless @file_name == @file_set.original_file_name

    uri = URI(@file_set.original_uri)
    request = Net::HTTP::Get.new(uri)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    send_data response.body, filename: @file_name, disposition: disposition, content_type: content_type
  end

end
