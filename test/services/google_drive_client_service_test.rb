require 'test_helper'

class GoogleDriveClientServiceTest < ActiveSupport::TestCase

  test 'should raise ArgumentError when not given correct arguments' do
    assert_raise(ArgumentError) do
      GoogleDriveClientService.new
    end
  end

  test 'should get access_token when given correct arguments' do
    access_token = 'ACCESSTOKEN'

    google_drive_client = GoogleDriveClientService.new(
      access_token: access_token,
      refresh_token: nil,
      expires_in: 3600,
      issued_at: Time.current
    )

    assert_equal(google_drive_client.access_token, access_token)
  end

  test 'should update access_token using refresh token when expired' do
    VCR.use_cassette('google_fetch_access_token', record: :none) do
      access_token = 'ACCESSTOKEN'
      refresh_token = 'REFRESHTOKEN'

      google_drive_client = GoogleDriveClientService.new(
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: 3600,
        issued_at: 3.months.ago
      )

      assert_equal(
        'RANDOMTOKEN',
        google_drive_client.access_token
      )
    end
  end

  test 'should be able to download spreadsheet' do
    access_token = 'ACCESSTOKEN'

    google_drive_client = GoogleDriveClientService.new(
      access_token: access_token,
      refresh_token: nil,
      expires_in: 3600,
      issued_at: Time.current
    )

    VCR.use_cassette('google_fetch_spreadsheet',
                     record: :none,
                     erb: {
                       collection_id: collections(:collection_fantasy).id,
                       community_id: communities(:community_books).id
                     }) do
      spreadsheet = google_drive_client.download_spreadsheet('RANDOMSPREADSHEETID')

      assert_equal(2, spreadsheet.count)
      assert_equal('Conference logo', spreadsheet.first['title'])
      assert_equal('Conference report', spreadsheet.last['title'])
    end
  end

  test 'should be able to download file' do
    access_token = 'ACCESSTOKEN'

    google_drive_client = GoogleDriveClientService.new(
      access_token: access_token,
      refresh_token: nil,
      expires_in: 3600,
      issued_at: Time.current
    )

    VCR.use_cassette('google_fetch_file', record: :none) do
      file = google_drive_client.download_file('RANDOMFILEID', 'logo.png')
      # Tempfile will use a unique indentifer in the name,
      # but it should start with logo and end with correct extension
      assert_match(/logo.*\.png/, File.basename(file.path))
      assert_equal('logo.png', file.original_filename)
    end
  end

  test 'should get authorization config' do
    authorization = GoogleDriveClientService.authorization

    assert_equal(Rails.application.secrets.google_client_id, authorization.client_id)
    assert_equal(Rails.application.secrets.google_client_secret, authorization.client_secret)
    assert_equal(
      Rails.application.routes.url_helpers.new_admin_google_session_url,
      authorization.redirect_uri.to_s
    )
  end

end
