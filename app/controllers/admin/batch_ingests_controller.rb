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
    return redirect_to google_callback_admin_batch_ingests_path if drive.nil?

    drive.list_files(
      q: file_query,
      order_by: 'modifiedTime desc,folder,name',
      supports_team_drives: true,
      include_team_drive_items: true,
      corpora: 'user,allTeamDrives',
      page_size: 10,
      fields: 'files(name,id,size,mimeType,modifiedTime,parents,webContentLink),nextPageToken'
    ) do |file_list, error|
      # Raise an exception if there was an error Google API's
      if error.present?
        # In order to properly trigger reauthentication, the token must be cleared
        # Additionally, the error is not automatically raised from the Google Client
        session[:credentials] = nil
        return redirect_to google_callback_admin_batch_ingests_path

        # TODO: Needs better logic here? only redirect when its auth error
        # Look into refresh token as well
      end

      @list_files = file_list

      # request_params.page_token = file_list.next_page_token
    end

    drive.list_files(
      q: spreadsheet_query,
      order_by: 'modifiedTime desc,folder,name',
      supports_team_drives: true,
      include_team_drive_items: true,
      corpora: 'user,allTeamDrives',
      page_size: 10,
      fields: 'files(name,id,size,mimeType,modifiedTime,parents,webContentLink),nextPageToken'
    ) do |spreadsheet_list, error|
      # Raise an exception if there was an error Google API's
      if error.present?
        # In order to properly trigger reauthentication, the token must be cleared
        # Additionally, the error is not automatically raised from the Google Client
        session[:credentials] = nil
        return redirect_to google_callback_admin_batch_ingests_path

        # TODO: Needs better logic here? only redirect when its auth error
        # Look into refresh token as well
      end

      @list_spreadsheets = spreadsheet_list

      # request_params.page_token = spreadsheet_list.next_page_token
    end

    # @list_files += list_files(drive, request_params, path: path) if request_params.page_token.present?

    @batch_ingest = BatchIngest.new
  end

  # POST /batch_ingests
  # POST /batch_ingests.json
  def create
    @batch_ingest = current_user.batch_ingests.new

    @batch_ingest.files = []
    file_ids = params['batch_ingest'].delete :file_ids
    file_ids.each_with_index do |file_id, index|
      next if file_id.blank?

      file_name = params['batch_ingest']['file_names'][index]
      @batch_ingest.files << { id: file_id, name: file_name }
    end
    params['batch_ingest'].delete :file_names

    @batch_ingest.spreadsheet = {}
    spreadsheet_id = params['batch_ingest'].delete :spreadsheet_id
    spreadsheet_name = params['batch_ingest'].delete :spreadsheet_name

    @batch_ingest.spreadsheet = { id: spreadsheet_id, name: spreadsheet_name}
    # Should open up CSV, run validations against it (like is all files accounted for? is required fileds present? etc)
    # if good, then simply create batch ingest object and queue up a job
    # when job runs...it will open CSV, create batch ingest with download files


    # drive.get_file(id)
    # consume_spreadsheet(spreadsheet_id)
    # article.image.attach(
    #   io: File.open('app/assets/images/news.jpg'),
    #   filename: 'nw.jpg'
    #   )
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
    client_secrets = Google::APIClient::ClientSecrets.new(
      {
        'web': {
          'client_id': Rails.application.secrets.google_client_id,
          'client_secret': Rails.application.secrets.google_client_secret
        }
      }
    )
    auth_client = client_secrets.to_authorization
    scope = Google::Apis::DriveV3::AUTH_DRIVE
    auth_client.update!(
      scope: scope,
      redirect_uri: google_callback_admin_batch_ingests_url
    )

    if request['code'].nil?
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri
    else
      auth_client.code = request['code']
      auth_client.fetch_access_token!
      auth_client.client_secret = nil
      session[:credentials] = auth_client.to_json
      redirect_to new_admin_batch_ingest_path
    end
  end

  private

  def drive
    @drive ||= if session.key?(:credentials) && session[:credentials]

                 client_opts = JSON.parse(session[:credentials])
                 auth_client = Signet::OAuth2::Client.new(client_opts)
                 drive = Google::Apis::DriveV3::DriveService.new
                 drive.authorization = auth_client

                 drive
               end
  end

  def spreadsheet_query
    'mimeType = \'application/vnd.google-apps.spreadsheet\''
  end

  def file_query
    field_queries = []
    contraints.each_pair do |field, constraints|
      field_constraint = constraints.join(" and #{field} ")
      field_queries << "#{field} #{field_constraint}"
    end
    field_queries.join(' ')
  end

  def contraints
    {
      'mimeType' => [
        '!= \'application/vnd.google-apps.audio\'',
        '!= \'application/vnd.google-apps.document\'',
        '!= \'application/vnd.google-apps.drawing\'',
        '!= \'application/vnd.google-apps.form\'',
        '!= \'application/vnd.google-apps.fusiontable\'',
        '!= \'application/vnd.google-apps.map\'',
        '!= \'application/vnd.google-apps.photo\'',
        '!= \'application/vnd.google-apps.presentation\'',
        '!= \'application/vnd.google-apps.script\'',
        '!= \'application/vnd.google-apps.site\'',
        '!= \'application/vnd.google-apps.spreadsheet\'',
        '!= \'application/vnd.google-apps.video\'',
        '!= \'application/vnd.google-apps.shortcut\''
      ]
    }
  end

  def consume_spreadsheet(spreadsheet_id)
    require 'google/apis/sheets_v4'
    service = Google::Apis::SheetsV4::SheetsService.new

    client_opts = JSON.parse(session[:credentials])
    auth_client = Signet::OAuth2::Client.new(client_opts)
    service.authorization = auth_client

    range = 'Data!A2:X'
    response = service.get_spreadsheet_values(spreadsheet_id, range)

    response
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
