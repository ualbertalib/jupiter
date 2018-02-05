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
    return render status: :not_found if @file_set.blank?
    return render status: :not_found unless @file_name == @file_set.contained_filename

    authorize @file_set.owning_item, :download?
  end

  # Streaming code adapted from:
  # https://github.com/samvera/hydra-head/blob/9dcdc3b226c56a27024b6fb78b0d67a618ba5d2a/hydra-core/\
  #         app/controllers/concerns/hydra/controller/download_behavior.rb

  def stream_from_fedora(disposition: nil, content_type: nil)
    @file_set.unlock_and_fetch_ldp_object do |unlocked_fileset|
      response.headers['Accept-Ranges'] = 'bytes'
      if request.head?
        send_head(unlocked_fileset.original_file)
      else
        send_file_headers(unlocked_fileset, unlocked_fileset.original_file,
                          disposition: disposition, content_type: content_type)
        if request.headers['HTTP_RANGE']
          stream_file_body(unlocked_fileset.original_file.stream(request.headers['HTTP_RANGE']))
        else
          stream_file_body(unlocked_fileset.original_file.stream)
        end
      end
    end
  end

  def send_head(file)
    response.headers['Content-Length'] = file.size
    head :ok, content_type: file.mime_type
  end

  def send_file_headers(unlocked_fileset, file, disposition: nil, content_type: nil)
    disposition ||= 'inline'
    content_type ||= file.mime_type
    headers = { filename: @file_name, disposition: disposition, content_type: content_type }

    if request.headers['HTTP_RANGE']
      self.status = 206
      _, range = request.headers['HTTP_RANGE'].split('bytes=')
      from, to = range.split('-').map(&:to_i)
      to ||= file.size - 1
      length = to - from + 1
      response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
      response.headers['Content-Length'] = length.to_s
    else
      self.status = 200
      send_file_headers!(headers)
      response.headers['Content-Length'] ||= file.size.to_s
    end
    # Prevent Rack::ETag from calculating a digest over body
    response.headers['Last-Modified'] = unlocked_fileset.modified_date.utc.strftime('%a, %d %b %Y %T GMT')
    self.content_type = content_type
  end

  def stream_file_body(iostream)
    unless response.headers['Last-Modified'] || response.headers['ETag']
      Rails.logger.warn('Response may be buffered instead of streaming, best to set a Last-Modified or ETag header')
    end
    iostream.each do |in_buff|
      response.stream.write(in_buff)
    end
  ensure
    response.stream.close
  end

end
