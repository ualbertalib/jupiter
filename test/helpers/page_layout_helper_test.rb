require 'test_helper'

class PageLayoutHelperTest < ActionView::TestCase

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

  # page_image

  test 'page_image defaults to the jupiter logo' do
    assert_equal image_url('era-logo.png'), page_image
  end

  test 'page_image should return default image on community/item with no logo' do
    @community = Community.new_locked_ldp_object(title: 'Random community', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)

    assert_equal image_url('era-logo.png'), page_image
  end

  test 'page_image should return community/item logo' do
    @community = Community.new_locked_ldp_object(title: 'Random community', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)

    @community.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                           filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    assert_equal page_image, @community.thumbnail_url
  end

end
