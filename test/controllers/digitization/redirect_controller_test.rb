require 'test_helper'

class Digitization::RedirectControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! URI('http://digitization.ualberta.localhost').host
  end

  test 'should redirect Peel monograph' do
    # Action: redirect#peel_book
    get '/bibliography/4062.html'
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
    get '/bibliography/3178.1.1.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_book_url(digitization_books(:henderson))
  end

  test 'should redirect Peel Henderson directory page level to the top level' do
    # Action: redirect#peel_book
    get '/bibliography/3178.1.1/44.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_book_url(digitization_books(:henderson))
  end

  test 'should redirect Peel Folk Fest pamphlet' do
    # Action: redirect#peel_book
    get '/bibliography/10572.1.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_book_url(digitization_books(:folk_fest))
  end

  test 'should redirect Peel Folk Fest pamphlet page level to the top level' do
    # Action: redirect#peel_book
    get '/bibliography/10572.1/36.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_book_url(digitization_books(:folk_fest))
  end

  test 'should redirect Peel newspaper' do
    # Action: redirect#peel_newspaper
    get '/newspapers/LSV/1967/03/29'
    assert_response :moved_permanently
    assert_redirected_to digitization_newspaper_url(digitization_newspapers(:la_survivance))
  end

  test 'should redirect Peel newspaper article level to the issue level' do
    # Action: redirect#peel_newspaper
    get '/newspapers/LSV/1967/03/29/5/Ar00501.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_newspaper_url(digitization_newspapers(:la_survivance))
  end

  test 'should redirect Peel Magee photograph' do
    # Action: redirect#peel_image
    get '/magee/MGNGBG0001.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_image_url(digitization_images(:magee))
  end

  test 'should redirect Peel Prairie postcard' do
    # Action: redirect#peel_image
    get '/postcards/PC015716.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_image_url(digitization_images(:postcard))
  end

  test 'should redirect Peel Prairie postcard view to the top level' do
    # Action: redirect#peel_image
    get '/postcards/PC015716.html#n2'
    assert_response :moved_permanently
    assert_redirected_to digitization_image_url(digitization_images(:postcard))
  end

  test 'should redirect Peel map' do
    # Action: redirect#peel_map
    get '/maps/M000230.html'
    assert_response :moved_permanently
    assert_redirected_to digitization_map_url(digitization_maps(:map))
  end

  test 'should redirect Peel map view to the top level' do
    # Action: redirect#peel_map
    get '/maps/M000230.html?view=big'
    assert_response :moved_permanently
    assert_redirected_to digitization_map_url(digitization_maps(:map))
  end

end
