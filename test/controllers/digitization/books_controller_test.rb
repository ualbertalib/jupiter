require 'test_helper'

class Digitization::BooksControllerTest < ActionDispatch::IntegrationTest

  setup do
    @digitization_book = digitization_books(:peel_monograph)
  end

  test 'should show digitization_book' do
    get book_url(@digitization_book)
    assert_response :success
  end

end
