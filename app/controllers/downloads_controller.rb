class DownloadsController < ApplicationController

  include ActiveStorage::SetBlob

  # Needed for Activestorage compatibility, normally happens in ActiveStorage::BaseController for controllers that subclass is
  # see https://github.com/rails/rails/blob/master/activestorage/app/controllers/active_storage/base_controller.rb
  before_action do
    ActiveStorage::Current.host = request.base_url
  end

  before_action :load_and_authorize_file, only: [:view, :download]
  after_action :update_download_count, only: [:view, :download], unless: -> { request.bot? }

  # Used to serve files from the "permanent" vanity URLS /items/item_id/view/file_set_id/filesname and
  # /items/item_id/download/file_set_id/
  def view
    requested_filename = params[:file_name]
    filename = @file.filename.to_s

    # We distribute view URLs via OAI that have all spaces mapped to underscores, because
    # LAC, who we have to support with our OAI implementation, absolutely cannot handle spaces
    # special-casing this is the easiest work-around ¯\_(ツ)_/¯
    raise JupiterCore::ObjectNotFound unless (requested_filename == filename) ||
                                             (requested_filename == filename.tr(' ', '_'))

    send_data(ActiveStorage::Blob.service.download(@file.blob.key), disposition: 'inline',
                                                                    type: @file.blob.content_type)
  end

  def download
    send_data(ActiveStorage::Blob.service.download(@file.blob.key), disposition: 'attachment',
                                                                    type: @file.blob.content_type)
  end

  private

  def load_and_authorize_file
    @file = ActiveStorage::Attachment.find_by(fileset_uuid: params[:file_set_id])
    raise JupiterCore::ObjectNotFound unless @file.record_id == params[:id]

    authorize @file.record, :download?
  end

  def update_download_count
    Statistics.increment_download_count_for(item_id: params[:id], ip: request.ip)
  rescue StandardError => e
    # Trap errors so that if Redis goes down or similar, downloads don't start crashing
    Rollbar.error("Error incrementing download count for #{params[:id]}", e)
  end

end
