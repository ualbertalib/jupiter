# frozen_string_literal: true

# NOTE: If we ever upgrade VCR to v6.0+ then this monkeypatch
# will not be needed anymore and can be safely removed
# More info: https://github.com/vcr/vcr/pull/907/files
#
# This code was inspired by the patch suggested here: https://github.com/vcr/vcr/pull/907#issuecomment-1038958113
if Rails.env.test?
  require 'vcr'
  require 'vcr/library_hooks/webmock'

  module VCR::LibraryHooks::WebMock
    def global_hook_disabled?(request)
      requests = Thread.current[:_vcr_webmock_disabled_requests]
      requests&.include?(request)
    end

    def global_hook_disabled_requests
      Thread.current[:_vcr_webmock_disabled_requests] ||= []
    end
  end
end
