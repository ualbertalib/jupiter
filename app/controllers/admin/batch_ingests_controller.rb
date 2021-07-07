class Admin::BatchIngestsController < Admin::AdminController

  def index
    @search = BatchIngest.ransack(params[:q])
    @search.sorts = 'created_at desc' if @search.sorts.empty?

    @batch_ingests = @search.result.page(params[:page])
  end

  def show
    @batch_ingest = BatchIngest.find(params[:id])
  end

  def new
    @access_token = fetch_access_token
    if @access_token
      @developer_key = Rails.application.secrets.google_developer_key
      @batch_ingest = BatchIngest.new
    else
      redirect_to new_admin_google_session_path
    end
  end

  def create
    @batch_ingest = current_user.batch_ingests.new(
      access_token: session[:google_credentials]['access_token'],
      refresh_token: session[:google_credentials]['refresh_token'],
      expires_in: session[:google_credentials]['expires_in'],
      issued_at: session[:google_credentials]['issued_at']
    )

    @batch_ingest.assign_attributes(permitted_attributes(BatchIngest))

    if @batch_ingest.save
      # TODO: queue a background job for the actual batch ingestion
      # BatchIngestionJob.perform_later(@batch_ingest.id)

      redirect_to [:admin, @batch_ingest], notice: t('.created')
    else
      @access_token = fetch_access_token
      if @access_token
        @developer_key = Rails.application.secrets.google_developer_key
        render :new
      end
    end
  end

  private

  def fetch_access_token
    if session[:google_credentials] &&
       session[:google_credentials]['access_token']
      GoogleDriveClientService.new(
        access_token: session[:google_credentials]['access_token'],
        refresh_token: session[:google_credentials]['refresh_token'],
        expires_in: session[:google_credentials]['expires_in'],
        issued_at: session[:google_credentials]['issued_at']
      ).access_token
    end
  end

end
