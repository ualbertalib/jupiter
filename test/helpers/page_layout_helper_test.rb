require 'test_helper'

class PageLayoutHelperTest < ActionView::TestCase
  include Webpacker::Helper

  attr_reader :request

  def setup
    @request = Class.new do
      def base_url
        'https://example.com'
      end
    end.new
  end

  # page_title

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
    @community = Community.create!(title: 'Random community', owner_id: users(:admin).id)

    assert_equal asset_pack_url('media/images/era-logo.png'), page_image_url
  end

  test 'page_image_url should return community/item logo' do
    @community = Community.create!(title: 'Random community', owner_id: users(:admin).id)

    @community.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                           filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    assert_equal page_image_url, request.base_url + @community.thumbnail_path
  end

  test 'canonical_href is returning the correct canoncial url' do
    assert_equal Jupiter::PRODUCTION_URL, canonical_href(nil)
    assert_equal Jupiter::PRODUCTION_URL, canonical_href('/')
    assert_equal "#{Jupiter::PRODUCTION_URL}/search", canonical_href('/search')
    assert_equal "#{Jupiter::PRODUCTION_URL}/search/nested", canonical_href('/search/nested')
  end

end
