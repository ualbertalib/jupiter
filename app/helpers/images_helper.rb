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
end
