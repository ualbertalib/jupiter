require 'application_system_test_case'

class Digitization::BookShowTest < ApplicationSystemTestCase

  setup do
    host! 'http://digitalcollections.ualberta.localhost'
  end
  test 'Books are working correctly' do
    visit digitization_book_url(digitization_books(:folk_fest))

    assert_selector 'h1', text: 'Edmonton Folk Music Festival', count: 1
    assert_selector 'dt', text: 'Type of Item', count: 1
    assert_selector 'dd a', text: 'Text', count: 1
  end

end
