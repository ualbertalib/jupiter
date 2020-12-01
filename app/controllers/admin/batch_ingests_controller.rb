class Admin::BatchIngestsController < Admin::AdminController

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
    @batch_ingest = BatchIngest.new
  end

  # POST /batch_ingests
  # POST /batch_ingests.json
  def create
    @batch_ingest = current_user.batch_ingests.new(permitted_attributes(BatchIngest))

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

end
