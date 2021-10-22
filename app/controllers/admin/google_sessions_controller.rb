class Admin::GoogleSessionsController < Admin::AdminController

  def new
    auth_client = GoogleDriveClientService.authorization

    if params['code'].nil?
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri
    else
      auth_client.code = params['code']
      auth_client.fetch_access_token!
      auth_client.client_secret = nil

      session[:google_credentials] = {}
      session[:google_credentials]['access_token'] = auth_client.access_token
      session[:google_credentials]['refresh_token'] = auth_client.refresh_token
      session[:google_credentials]['expires_in'] = auth_client.expires_in
      session[:google_credentials]['issued_at'] = auth_client.issued_at

      redirect_to new_admin_batch_ingest_path
    end
  end

end
