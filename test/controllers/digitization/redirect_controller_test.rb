require 'test_helper'

class Digitization::RedirectControllerTest < ActionDispatch::IntegrationTest

    setup do
        host! URI('http://digitization.ualberta.localhost').host
    end

    test 'should redirect Peel monograph' do
        # Action: redirect#peel_book
        get '/bibliography/4062'
        assert_response :moved_permanently
        assert_redirected_to digitization_book_url(digitization_books(:peel_monograph))
    end

    test 'should redirect Peel monograph page level to the top level of the book' do
        # Action: redirect#peel_book
        get '/bibliography/4062/85.html'
        assert_response :moved_permanently
        assert_redirected_to digitization_book_url(digitization_books(:peel_monograph))
    end

    test 'should redirect Peel Henderson directory' do
        # Action: redirect#peel_book
        get '/bibliography/3178/1/1'
        assert_response :moved_permanently
        assert_redirected_to digitization_book_url(digitization_books(:henderson))
    end

    test 'should redirect Peel Folk Fest pamphlet' do
        # Action: redirect#peel_book
        get '/bibliography/10572/1'
        assert_response :moved_permanently
        assert_redirected_to digitization_book_url(digitization_books(:folk_fest))
    end
end