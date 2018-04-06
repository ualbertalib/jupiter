require 'test_helper'

class PageLayoutHelperTest < ActionView::TestCase

  context '#page_title' do
    should 'should return the page title when given one' do
      assert_equal t('site_name'), page_title(t('site_name'))
    end

    should 'should concat multiple page titles together when called multiple times' do
      page_title(t('admin.users.index.header'))
      page_title(t('admin.header'))
      assert_equal "#{t('admin.users.index.header')} | #{t('admin.header')} | #{t('site_name')}",
                   page_title(t('site_name'))
    end
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


    assert_match /natoque penatibus et...\z/, page_description
  end

  test 'page_description sanitizes all html' do
    page_description('<b>Bold</b> <h1>Header</h1>')

    assert_equal 'Bold Header', page_description
  end
  # page_image
end




# describe 'page_image' do
#   it 'defaults to the GitLab logo' do
#     expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
#   end

#   %w(project user group).each do |type|
#     context "with @#{type} assigned" do
#       it "uses #{type.titlecase} avatar if available" do
#         object = double(avatar_url: 'http://example.com/uploads/-/system/avatar.png')
#         assign(type, object)

#         expect(helper.page_image).to eq object.avatar_url
#       end

#       it 'falls back to the default when avatar_url is nil' do
#         object = double(avatar_url: nil)
#         assign(type, object)

#         expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
#       end
#     end

#     context "with no assignments" do
#       it 'falls back to the default' do
#         expect(helper.page_image).to match_asset_path 'assets/gitlab_logo.png'
#       end
#     end
#   end
# end
