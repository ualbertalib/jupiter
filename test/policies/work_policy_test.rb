require 'test_helper'

class WorkPolicyTest < ActiveSupport::TestCase

  context 'admin user' do
    should 'have proper authorization over works' do
      current_user = users(:admin)
      work = Work.new_locked_ldp_object

      assert WorkPolicy.new(current_user, work).index?
      assert WorkPolicy.new(current_user, work).create?
      assert WorkPolicy.new(current_user, work).new?
      assert WorkPolicy.new(current_user, work).show?
      assert WorkPolicy.new(current_user, work).edit?
      assert WorkPolicy.new(current_user, work).update?
      assert WorkPolicy.new(current_user, work).destroy?
    end
  end

  context 'general user' do
    should 'only be able to access your own works' do
      current_user = users(:user)
      work = Work.new_locked_ldp_object

      assert WorkPolicy.new(current_user, work).index?
      assert WorkPolicy.new(current_user, work).show?

      assert WorkPolicy.new(current_user, work).create?
      assert WorkPolicy.new(current_user, work).new?
      assert WorkPolicy.new(current_user, work).edit?
      assert WorkPolicy.new(current_user, work).update?
      assert WorkPolicy.new(current_user, work).destroy?
    end

    # # TODO: Need to figure out how to check if owner/creator of a work
    # should 'cannot access other works' do
    #   current_user = users(:user)
    #   another_user = users(:admin)
    #   work = Work.new_locked_ldp_object(creator: another_user)

    #   assert WorkPolicy.new(current_user, work).index?
    #   assert WorkPolicy.new(current_user, work).show?

    #   assert WorkPolicy.new(current_user, work).create?
    #   assert WorkPolicy.new(current_user, work).new?

    #   refute WorkPolicy.new(current_user, work).edit?
    #   refute WorkPolicy.new(current_user, work).update?
    #   refute WorkPolicy.new(current_user, work).destroy?
    # end
  end

  context 'anon user' do
    should 'only be able to see index and show of works' do
      current_user = nil
      work = Work.new_locked_ldp_object

      assert WorkPolicy.new(current_user, work).index?
      assert WorkPolicy.new(current_user, work).show?

      refute WorkPolicy.new(current_user, work).create?
      refute WorkPolicy.new(current_user, work).new?
      refute WorkPolicy.new(current_user, work).edit?
      refute WorkPolicy.new(current_user, work).update?
      refute WorkPolicy.new(current_user, work).destroy?
    end
  end

end
