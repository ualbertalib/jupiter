module ImagesHelper

# Probably easier way of doing this?
  def file_icon(content_type)
    case content_type
    when /^image/
      'file-image-o'
    when /^audio/
      'file-audio-o'
    when /^video/
      'file-video-o'
    when /^text/
      'file-text-o'
    when /pdf/
      'file-pdf-o'
    when /zip/
      'file-archive-o'
    when /(excel|sheet)/
      'file-excel-o'
    when /(powerpoint|presentation)/
      'file-powerpoint-o'
    when /word/
      'file-word-o'
    else
      'file-o'
    end
  end

  # TODO: Remove this after upgrading activestorage to rails 5.2
  # Returns true if the content_type of this blob is in the image range, like image/png.
  # https://github.com/rails/rails/blob/7b1dfac29146ddda82d1ee226cdb8ef281013502/activestorage/app/models/active_storage/blob.rb#L95
  def image?(file_attachment)
    file_attachment.content_type.start_with?('image')
  end
end
