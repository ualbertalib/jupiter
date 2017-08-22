require 'test_helper'

class CommunitiesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    sign_in_as @admin
    @community = Community.new_locked_ldp_object(title: 'Nice book',
                                                 owner: @admin.id)
  end

  test 'should get index' do
    get communities_url
    assert_response :success
  end

  test 'should get new' do
    get new_community_url
    assert_response :success
  end

  test 'should create community' do
    # This mocks the argument for the unlock_and_fetch_ldp_object block
    ldp_object_mock = Minitest::Mock.new
    ldp_object_mock.expect :save!, true

    Community.stub :new_locked_ldp_object, @community do
      @community.stub :unlock_and_fetch_ldp_object, true, ldp_object_mock do
        @community.stub :to_param, '90210' do
          post communities_url, params: { community: { title: 'Whatever' } }
          assert_redirected_to community_url(@community)
        end
      end
    end
    ldp_object_mock.verify
  end

  test 'should show community' do
    Community.stub :find, @community do
      @community.stub :to_param, '90210' do
        get community_url(@community)
        assert_response :success
      end
    end
  end

  test 'should get edit' do
    Community.stub :find, @community do
      @community.stub :to_param, '90210' do
        get edit_community_url(@community)
        assert_response :success
      end
    end
  end

  test 'should update community' do
    Community.stub :find, @community do
      @community.stub :to_param, '90210' do
        patch community_url(@community), params: { community: { title: 'Whatever' } }
        assert_redirected_to community_url(@community)
      end
    end
  end

  test 'should destroy community' do
    # This mocks the argument for the unlock_and_fetch_ldp_object block
    ldp_object_mock = Minitest::Mock.new
    ldp_object_mock.expect :destroy, true

    Community.stub :find, @community do
      @community.stub :to_param, '90210' do
        @community.stub :unlock_and_fetch_ldp_object, true, ldp_object_mock do
          delete community_url(@community)
        end
      end
    end
    assert_redirected_to admin_communities_and_collections_url
    ldp_object_mock.verify
  end

end
