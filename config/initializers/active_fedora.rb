def baseurl
  "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/"
end

# ID to pairtree mappings for ActiveFedora
# drastically simpler than NOID equivalents
# Fedora retains the job of minting UUIDs,
# eliminating the minter bottleneck
ActiveFedora::Base.translate_uri_to_id = lambda do |uri|
  # remove the base url, and the UUID will be the 5th part of the split. Any
  # slashes after that are sub-resources of the UUID
  # reverse engineered from this gibberish:
  # https://github.com/samvera/active_fedora-noid/blob/0c2dac74ff83557496512b8b40479e106b827279/lib/active_fedora/noid/config.rb#L42
  uri.to_s.sub(baseurl, '').split('/', 5).last
end

# take the first 8 chars, split every 2 characters, interleave with an array containing 4 slashes,
# and compact back into a string.
# e1d01031-4769-4dd2-8618-7c0a6bab72bb
# becomes
# e1/d0/10/31/e1d01031-4769-4dd2-8618-7c0a6bab72bb
ActiveFedora::Base.translate_id_to_uri = lambda do |id|
  baseurl + id[0, 8].scan(/../).zip(['/'] * 4).join + id
end
