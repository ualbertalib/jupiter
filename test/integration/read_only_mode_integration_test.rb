require 'test_helper'
require 'rake'
Rails.application.load_tasks

class ReadOnlyModeIntegrationTest < ActionDispatch::IntegrationTest

  setup do
    Announcement.destroy_all
  end

  test 'read only mode logs out' do
    $stdout.stub(:puts, nil) do
      sign_in_as users(:user_regular)
      get root_path
      assert_select 'a#jupiter-user-nav-downdown', count: 1
      Rake::Task['jupiter:enable_read_only_mode'].execute
      get root_path
      assert_select 'a#jupiter-user-nav-downdown', count: 0
      Rake::Task['jupiter:disable_read_only_mode'].execute
    end
  end

  test 'read only mode creates and clears announcement' do
    skip('This consistently flaps for me locally')
    $stdout.stub(:puts, nil) do
      sign_in_as users(:user_regular)
      get root_path
      assert_select 'div.alert', text: I18n.t('announcement_templates.read_only_mode'), count: 0
      Rake::Task['jupiter:enable_read_only_mode'].execute
      get search_path
      assert_select 'div.alert', text: I18n.t('announcement_templates.read_only_mode'), count: 1
      Rake::Task['jupiter:disable_read_only_mode'].execute
      get root_path
      assert_select 'div.alert', text: I18n.t('announcement_templates.read_only_mode'), count: 0
    end
  end

  test 'cannot log in when read only mode enabled' do
    $stdout.stub(:puts, nil) do
      get root_path
      assert_select 'a.nav-item', text: I18n.t('application.navbar.links.login'), count: 1
      Rake::Task['jupiter:enable_read_only_mode'].execute
      get root_path
      assert_select 'a.nav-item', text: I18n.t('application.navbar.links.login'), count: 0
      Rake::Task['jupiter:disable_read_only_mode'].execute
      get root_path
      assert_select 'a.nav-item', text: I18n.t('application.navbar.links.login'), count: 1
    end
  end

end
