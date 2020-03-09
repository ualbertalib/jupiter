module ImagesHelper
  # Probably easier way of doing this?
  def file_icon(content_type)
    case content_type
    when /^image/
      'file-image'
    when /^audio/
      'file-audio'
    when /^video/
      'file-video'
    when /^text/
      'file-alt'
    when /pdf/
      'file-pdf'
    when /zip/
      'file-archive'
    when /(excel|sheet)/
      'file-excel'
    when /(powerpoint|presentation)/
      'file-powerpoint'
    when /word/
      'file-word'
    else
      'file'
    end
  end

  def safe_thumbnail_tag(thumbnail, image_tag_options)
    image_tag_options[:class] = 'j-thumbnail img-thumbnail'
    image_tag_options[:onerror] = "this.onerror=null;this.src='#{
      asset_pack_url('media/images/era-logo-without-text.png')
    }';"

    image_tag(thumbnail, image_tag_options)
  end
end
