class DownloadsController < ApplicationController
  include ActiveStorage::SetBlob

  # Needed for Activestorage compatibility, normally happens in ActiveStorage::BaseController for controlelrs that subclass is
  # see https://github.com/rails/rails/blob/master/activestorage/app/controllers/active_storage/base_controller.rb
  before_action do
    ActiveStorage::Current.host = request.base_url
  end

  before_action :load_and_authorize_file, only: [:view, :download]
  after_action :update_download_count, only: [:view, :download], unless: -> { request.bot? }

  # Used to serve files from the "permanent" vanity URLS /items/item_id/view/file_set_id/filesname and
  # /items/item_id/download/file_set_id/
  def view
    file_name = params[:file_name]
    raise JupiterCore::ObjectNotFound unless file_name == @file_set.contained_filename
    send_data(ActiveStorage::Blob.service.download(@file.blob.key), disposition: params[:disposition],
                                                                    content_type: params[:content_type])
  end

  def download
    send_data(ActiveStorage::Blob.service.download(@file.blob.key), disposition: 'attachment',
                                                                    content_type: params[:content_type])
  end

  private

  def load_and_authorize_file
    @file_set = FileSet.find(params[:file_set_id])
    raise JupiterCore::ObjectNotFound unless @file_set.item == params[:id]

    authorize @file_set.owning_item, :download?
    @file = @file_set.owning_item.files_attachments.where(fileset_uuid: @file_set.id).first
    raise ActiveRecord::RecordNotFound, "no attachment for file_set with UUID: #{@file_set.id} " unless @file.present?
  end

  def update_download_count
    Statistics.increment_download_count_for(item_id: params[:id], ip: request.ip)
  rescue StandardError => e
    # Trap errors so that if Redis goes down or similar, downloads don't start crashing
    Rollbar.error("Error incrementing download count for #{params[:id]}", e)
  end

end
