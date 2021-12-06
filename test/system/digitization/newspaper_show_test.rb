require 'application_system_test_case'

class Digitization::NewspaperShowTest < ApplicationSystemTestCase

  setup do
    Capybara.app_host = 'http://digitalcollections.ualberta.localhost'
  end
  test 'Newspapers are working correctly' do
    visit digitization_newspaper_url(digitization_newspapers(:central_alberta_news))

    assert_selector 'h1', text: 'The advertiser and central Alberta news', count: 1
    assert_selector 'dt', text: 'Type of Item', count: 1
    assert_selector 'dd a', text: 'Text', count: 1
  end

end
