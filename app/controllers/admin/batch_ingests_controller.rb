class Admin::BatchIngestsController < Admin::AdminController

  require 'google/apis/drive_v3'
  require 'google/api_client/client_secrets'

  # GET /batch_ingests
  # GET /batch_ingests.json
  def index
    @batch_ingests = BatchIngest.all
  end

  # GET /batch_ingests/1
  # GET /batch_ingests/1.json
  def show
    @batch_ingest = BatchIngest.find(params[:id])
  end

  # GET /batch_ingests/new
  def new
    if google_credentials
      @access_token = google_credentials.access_token
      @batch_ingest = BatchIngest.new
    else
      return redirect_to google_callback_admin_batch_ingests_path
    end
  end

  # POST /batch_ingests
  # POST /batch_ingests.json
  def create
    @batch_ingest = current_user.batch_ingests.new

    @batch_ingest.files = []
    file_ids = params['batch_ingest'].delete :file_ids
    file_ids = [] if file_ids.blank?
    file_ids.each_with_index do |file_id, index|
      next if file_id.blank?

      file_name = params['batch_ingest']['file_names'][index]
      @batch_ingest.files << { id: file_id, name: file_name }
    end
    params['batch_ingest'].delete :file_names

    @batch_ingest.spreadsheet = {}
    spreadsheet_id = params['batch_ingest'].delete :spreadsheet_id
    spreadsheet_name = params['batch_ingest'].delete :spreadsheet_name

    @batch_ingest.spreadsheet = { id: spreadsheet_id, name: spreadsheet_name }

    # Should open up CSV, run validations against it (like is all files accounted for? is required fileds present? etc)
    # if good, then simply create batch ingest object and queue up a job
    # when job runs...it will open CSV, create batch ingest with download files

    # consume_spreadsheet(spreadsheet_id)


    @batch_ingest.assign_attributes(permitted_attributes(BatchIngest))

    respond_to do |format|
      if @batch_ingest.save
        format.html { redirect_to [:admin, @batch_ingest], notice: 'Batch ingest was successfully created.' }
        format.json { render :show, status: :created, location: @batch_ingest }
      else
        format.html { render :new }
        format.json { render json: @batch_ingest.errors, status: :unprocessable_entity }
      end
    end
  end

  def google_callback
    auth_client = google_authorization.dup

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

  private

  def google_authorization
    client_secrets = Google::APIClient::ClientSecrets.new(
      {
        'web': {
          'client_id': Rails.application.secrets.google_client_id,
          'client_secret': Rails.application.secrets.google_client_secret
        }
      }
    )
    google_authorization = client_secrets.to_authorization
    scope = Google::Apis::DriveV3::AUTH_DRIVE
    google_authorization.update!(
      scope: scope,
      redirect_uri: google_callback_admin_batch_ingests_url
    )

    google_authorization
  end

  def google_credentials
    if session[:google_credentials] && session[:google_credentials]['access_token']
      @google_credentials ||= (
        auth = google_authorization.dup
        auth.update_token!(session[:google_credentials])

        if auth.expired?
          auth.refresh! if session[:google_credentials]['refresh_token']
          nil
        else
          auth
        end
      )
    end
  end


  def consume_file(file_id)
    # TODO: Need this code for downloading files/spreadsheets
    #  client_opts = JSON.parse(session[:credentials])["access_token"]
    #  auth_client = Signet::OAuth2::Client.new(client_opts)
    #  drive = Google::Apis::DriveV3::DriveService.new
    #  drive.authorization = auth_client
    #  drive
    # drive.get_file(id)

    # item.files.attach(
    #   io: File.open('app/assets/images/news.jpg'),
    #   filename: 'nw.jpg'
    #   )
  end

  def consume_spreadsheet(spreadsheet_id)


    require 'google/apis/sheets_v4'
    service = Google::Apis::SheetsV4::SheetsService.new

    client_opts = JSON.parse(session[:credentials])
    auth_client = Signet::OAuth2::Client.new(client_opts)
    service.authorization = auth_client

    range = 'Data!A2:X'
    service.get_spreadsheet_values(spreadsheet_id, range)

    # Validate CSV?
    #
    # then Each row, go through columns, download file and create draft_items
    #
    # response.values.each do |row|
    #
    #
    # end
  end

end
