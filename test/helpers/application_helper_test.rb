class ApplicationHelperTest < ActionView::TestCase

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

end
