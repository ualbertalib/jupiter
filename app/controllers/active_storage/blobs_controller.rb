class ActiveStorage::BlobsController < ActiveStorage::BaseController

  include ActiveStorage::SetBlob

  # overrides the base ActiveStorage::Blobs controller method to remove expiring key verification
  def show
    if @blob.present?
      send_data(ActiveStorage::Blob.service.download(@blob.key), disposition: params[:disposition],
                                                                 content_type: params[:content_type])
    else
      head :not_found
    end
  end

end
