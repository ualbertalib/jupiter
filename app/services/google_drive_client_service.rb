class GoogleDriveClientService

  attr_reader :access_token

  def initialize(access_token:, refresh_token:, expires_in:, issued_at:)
    @access_token = access_token
    @refresh_token = refresh_token
    @expires_in = expires_in
    @issued_at = issued_at

    update_google_credentials
  end

  def self.authorization
    client_secrets = Google::APIClient::ClientSecrets.new(
      {
        web: {
          client_id: Rails.application.secrets.google_client_id,
          client_secret: Rails.application.secrets.google_client_secret
        }
      }
    )
    authorization = client_secrets.to_authorization
    scope = [Google::Apis::DriveV3::AUTH_DRIVE, Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY]
    authorization.update!(
      scope: scope,
      redirect_uri: Rails.application.routes.url_helpers.new_admin_google_session_url,
      additional_parameters: {
        prompt: 'consent' # This is the only way to get a new refresh token if we have authenticated before
      }
    )

    authorization
  end

  def download_spreadsheet(spreadsheet_id)
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = google_credentials
    service.key = Rails.application.secrets.google_developer_key

    range = "'Data'!A:X"

    # TODO: Add better error handling
    #  E.g: handle bad request: Unable to parse range: 'Data'!A:X
    response = service.get_spreadsheet_values(spreadsheet_id, range)

    rows = response.values

    headers = rows.shift
    data = rows.map do |row|
      headers.zip(row).to_h
    end

    data || []
  end

  def download_file(file_id, file_name)
    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = google_credentials
    file = service.get_file(file_id, download_dest: Tempfile.new(file_name, binmode: true))
    file.rewind
    file
  end

  private

  def google_credentials
    return nil unless @access_token

    @google_credentials ||= begin
      auth = GoogleDriveClientService.authorization

      # Googleapis `.update_token!` expects options arguements that are not nil
      # lets parse any that are nil here using `.compact`
      options = {
        access_token: @access_token,
        refresh_token: @refresh_token,
        expires_in: @expires_in,
        issued_at: @issued_at
      }.compact

      auth.update_token!(options)

      if auth.expired?
        if auth.refresh_token
          auth.refresh!
          auth
        end
      else
        auth
      end
    end
  rescue Signet::AuthorizationError
    nil
  end

  def update_google_credentials
    auth_client = google_credentials

    if auth_client
      @access_token = auth_client.access_token
      @refresh_token = auth_client.refresh_token
      @expires_in = auth_client.expires_in
      @issued_at = auth_client.issued_at
    else
      @access_token = nil
      @refresh_token = nil
      @expires_in = nil
      @issued_at = nil
    end

    self
  end

end
