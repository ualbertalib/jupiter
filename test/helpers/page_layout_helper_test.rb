require 'test_helper'

class PageLayoutHelperTest < ActionView::TestCase

  include Webpacker::Helper

  attr_reader :request

  setup do
    @request = Class.new do
      def base_url
        'https://example.com'
      end
    end.new
  end

  # page_title

  test 'should return the page title when given one' do
    assert_equal t('site_name'), page_title(t('site_name'))
  end

  test 'should concat multiple page titles together when called multiple times' do
    page_title(t('admin.users.index.header'))
    page_title(t('admin.header'))
    assert_equal "#{t('admin.users.index.header')} | #{t('admin.header')} | #{t('site_name')}",
                 page_title(t('site_name'))
  end

  # TODO: Shouldn't escape amperstand, current bug here https://github.com/rails/rails-html-sanitizer/issues/56
  test 'page_title handles html entities and html tags correctly' do
    page_title('<b>Bold Text:</b> &amp; <h1>"Header"</h1>')

    assert_equal 'Bold Text: &amp; "Header"', page_title
  end

  # page_description

  test 'page_description defaults to welcome lead' do
    assert_equal I18n.t('welcome.index.welcome_lead'), page_description
  end

  test 'page_description returns last pushed description' do
    page_description('Foo')
    page_description('Bar')
    page_description('Baz')

    assert_equal 'Baz', page_description
  end

  test 'page_description squishes multiple newlines' do
    page_description("Foo\nBar\nBaz")

    assert_equal 'Foo Bar Baz', page_description
  end

  test 'page_description truncates long text' do
    text = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus. Donec quam felis,
    ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa
    quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget,
    arcu.'

    page_description(text)

    assert_match(/natoque penatibus et...\z/, page_description)
  end

  # TODO: Shouldn't escape amperstand, current bug here https://github.com/rails/rails-html-sanitizer/issues/56
  test 'page_description sanitizes all html and html entities correctly' do
    page_description('<b>Bold Text:</b> & <h1>"Header"</h1>')

    assert_equal 'Bold Text: &amp; "Header"', page_description
  end

  # page_image_url

  test 'page_image_url defaults to the jupiter logo' do
    assert_equal asset_pack_url('media/images/era-logo.png'), page_image_url
  end

  test 'page_image_url should return default image on community/item with no logo' do
    @community = communities(:books)

    assert_equal asset_pack_url('media/images/era-logo.png'), page_image_url
  end

  test 'page_image_url should return community/item logo' do
    @community = communities(:books)

    @community.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                           filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    assert_equal page_image_url, request.base_url + thumbnail_path(@community.thumbnail_file)
  end

  # thumbnail_path

  test 'thumbnail_path should return preview for pdf (Invariable but Previewable)' do
    community = communities(:books)
    collection = collections(:fantasy_books)
    @item = Item.new.tap do |uo|
      uo.title = 'Fantastic item'
      uo.owner_id = users(:admin).id
      uo.creators = ['Joe Blow', 'Smokey Chantilly-Tiffany', 'Céline Marie Claudette Dion']
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.created = '1999-09-09'
      uo.languages = [CONTROLLED_VOCABULARIES[:language].english]
      uo.license = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
      uo.item_type = CONTROLLED_VOCABULARIES[:item_type].article
      uo.publication_status = [CONTROLLED_VOCABULARIES[:publication_status].draft,
                               CONTROLLED_VOCABULARIES[:publication_status].submitted]
      uo.subject = ['Items']
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      # Attach a file to the item so that it provide preview
      File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
        @item.add_and_ingest_files([file])
      end
    end

    logo = @item.files.first
    expected = Rails.application.routes.url_helpers.rails_representation_path(
      logo.preview(resize: '100x100', auto_orient: true).processed
    )
    assert_equal expected, thumbnail_path(logo)
  end

  test 'thumbnail_path should return preview for image (Variable)' do
    community = communities(:books)
    collection = collections(:fantasy_books)
    @item = Item.new.tap do |uo|
      uo.title = 'Fantastic item'
      uo.owner_id = users(:admin).id
      uo.creators = ['Joe Blow', 'Smokey Chantilly-Tiffany', 'Céline Marie Claudette Dion']
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.created = '1999-09-09'
      uo.languages = [CONTROLLED_VOCABULARIES[:language].english]
      uo.license = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
      uo.item_type = CONTROLLED_VOCABULARIES[:item_type].article
      uo.publication_status = [CONTROLLED_VOCABULARIES[:publication_status].draft,
                               CONTROLLED_VOCABULARIES[:publication_status].submitted]
      uo.subject = ['Items']
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      # Attach a file to the item so that it can provide variant
      File.open(file_fixture('image-sample.jpeg'), 'r') do |file|
        @item.add_and_ingest_files([file])
      end
    end

    logo = @item.files.first
    expected = Rails.application.routes.url_helpers.rails_representation_path(
      logo.variant(resize: '100x100', auto_orient: true).processed
    )
    assert_equal expected, thumbnail_path(logo)
  end

  test 'thumbnail_path should provide nil if no thumbnail is possible (StandardError on variable)' do
    logo = active_storage_attachments(:logo)
    logo.define_singleton_method(:variant) { |_| throw StandardError }

    assert_nil thumbnail_path(logo)
    # TODO: assert that the logger.warn was written
  end

  test 'thumbnail_path should return nil if both the variant and preview fail' do
    logo = active_storage_attachments(:logo)
    logo.define_singleton_method(:variant) { |_| throw ActiveStorage::InvariableError }
    logo.define_singleton_method(:preview) { |_| throw StandardError }

    assert_nil thumbnail_path(logo)
    # TODO: assert that the logger.warn was written
  end

  # canonical_href

  test 'canonical_href is returning the correct canoncial url' do
    assert_equal Jupiter::PRODUCTION_URL, canonical_href(nil)
    assert_equal Jupiter::PRODUCTION_URL, canonical_href('/')
    assert_equal "#{Jupiter::PRODUCTION_URL}/search", canonical_href('/search')
    assert_equal "#{Jupiter::PRODUCTION_URL}/search/nested", canonical_href('/search/nested')
  end

end
