require 'i18n/backend/active_record'

Translation = I18n::Backend::ActiveRecord::Translation

if Translation.table_exists?
  I18n.backend = I18n::Backend::ActiveRecord.new

  I18n::Backend::ActiveRecord.include I18n::Backend::Memoize
  I18n::Backend::Simple.include I18n::Backend::Memoize
  I18n::Backend::Simple.include I18n::Backend::Pluralization

  I18n.backend = I18n::Backend::Chain.new(I18n::Backend::Simple.new, I18n.backend)
end

I18n::Backend::ActiveRecord.configure do |config|
  # config.cleanup_with_destroy = true # defaults to false
end
