class CombinationsController < ApplicationController
  before_action :set_combination, only: [:show, :edit, :update, :destroy, :calculate]
  #before_action :set_index_help, only: [:index, :unknown, :unrated]
  before_action :set_search_fields, only: [:index, :unknown, :unrated]
  before_action :set_sort_fields, only: [:index, :unknown, :unrated]
  #before_action :set_submit_help, only: [:new, :create]
  before_action :advanced_only_for_users, only: [:index, :unknown, :unrated]

  before_action :record_search, only: [:index, :unknown, :unrated]

  skip_before_filter :ensure_admin, :only => [:new, :create, :unknown, :unrated, :interogate]
  before_filter :ensure_community, :only => [:new, :create]

  def advanced_only_for_users
    unless params[:search].nil? && params[:order].nil?
      ensure_community
    end
  end

  def set_search_fields
    @search_fields = {
      'user_agents.value' => 'User Agent',
      'dhcp_vendors.value' =>  'DHCPv4 Vendor',
      'dhcp_fingerprints.value' => 'DHCPv4 Fingerprint',
      'dhcp6_fingerprints.value' => 'DHCPv6 Fingerprint',
      'dhcp6_enterprises.value' => 'DHCPv6 Enterprise',
      'devices.name' => 'Device name',
      'mac_vendors.name'=> 'Mac vendor name',
      'submitters.name'=> 'Submitter username',
    }
    return @search_fields
  end

  def set_sort_fields
    @sort_fields = set_search_fields
    @sort_fields['combinations.score'] = 'Score'
    @sort_fields['combinations.created_at'] = 'Discovered date'
    return @search_fields
  end

  def escaped_search
    search = String.new(params[:search]) unless params[:search].nil?
    #search = search.gsub!(/[+\-"]/, ' ')
    logger.debug "escaped_search #{search}"
    return search
  end

  # GET /combinations
  # GET /combinations.json
  def index
    params[:search] = params[:search] || ''
    @search = escaped_search
    @selected_fields = params[:fields]
    unless params[:search].empty?
      @combinations = Combination.simple_search(params[:search], @selected_fields, 'AND device_id IS NOT NULL').paginate(:page => params[:page])
    else
      @combinations = Combination.where('device_id IS NOT NULL').paginate(:page => params[:page])
    end
    order_results
  end

  def unknown
    params[:search] = params[:search] || ''
    @search = escaped_search
    @selected_fields = params[:fields]
    unless params[:search].empty?
      @combinations = Combination.simple_search(params[:search], @selected_fields, "AND device_id IS NULL").paginate(:page => params[:page])
    else
      @combinations = Combination.where("device_id IS NULL").paginate(:page => params[:page])
    end
    order_results
    render 'index'
  end

  def unrated
    params[:search] = params[:search] || ''
    @search = escaped_search
    @selected_fields = params[:fields]
    unless params[:search].empty?
      @combinations = Combination.simple_search(params[:search], @selected_fields, "AND device_id IS NOT NULL AND score=0").paginate(:page => params[:page])
    else
      @combinations = Combination.where("device_id IS NOT NULL AND score=0").paginate(:page => params[:page])
    end

    order_results
    render 'index'
  end

  # GET /combinations/1
  # GET /combinations/1.json
  def show
  end

  # GET /combinations/new
  def new
    @combination = Combination.new
    @initial_values = {}
  end

  def calculate 
    begin
      @combination.process(:with_version => true, :save => true)
      flash[:success] = "Combination was processed sucessfully. Yielded (Device='#{@combination.device.nil? ? "Unknown" : @combination.device.full_path}', Version='#{@combination.version}')"
      redirect_to :back
    rescue Exception => e
      flash[:error] = "An error happened while processing this combination. #{e.message}"
      redirect_to :back
    end
  end

  # POST /combinations
  # POST /combinations.json
  def create
    new_params = combination_params
    @initial_values  = {
      :user_agent_value => new_params[:user_agent_value],
      :dhcp_vendor_value => new_params[:dhcp_vendor_value],
      :dhcp_fingerprint_value => new_params[:dhcp_fingerprint_value],
      :mac_value => new_params[:mac_value],
    }

    @combination = Combination.get_or_create(:user_agent => new_params[:user_agent_value], :dhcp_vendor => new_params[:dhcp_vendor_value], :dhcp_fingerprint => new_params[:dhcp_fingerprint_value], :mac => new_params[:mac_value])
    if @combination.just_created
      @combination.submitter = @current_user
      @combination.device = Device.find(new_params[:device_id])
      @combination.version = new_params[:version]
      created = (@combination.validate_submition && @combination.save)
    else
      created = true
    end

    respond_to do |format|
      if created
        pending_combination = PendingCombination.create(:owner => @current_user, :combination => @combination, :comment => "Autocreated from submit page.", :new_device_id => new_params[:device_id], :new_version => new_params[:version])
        format.html { redirect_to @combination, notice: 'combination was successfully created.' }
        format.json { render :show, status: :created, location: @combination }
      else
        format.html { render :new }
        format.json { render json: @combination.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /combinations/1
  # DELETE /combinations/1.json
  def destroy
    @combination.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Combination was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def record_search
      unless params[:search].nil?
        @current_user.increment!(:search_count)
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_combination
      @combination = Combination.find(params[:id])
    end

    def order_results
      if params[:order]
        if @sort_fields.keys.include? params[:order]
          @order = params[:order]
          @order_way = params[:order_way] || 'desc'
        else
          flash.now[:error] = "Invalid sort field"
        end
      end

      unless @order
        @order = 'combinations.created_at'
        @order_way = 'desc'
        @default_order = true
      end

      @order_table = @order.split('.')[0]
      @combinations, fields = @combinations.add_join(@combinations, @order_table.singularize) unless @order_table == "combinations"
      @combinations = @combinations.order("#{@order} #{@order_way}")
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def combination_params
      params.require(:combination).permit(:version, :score, :user_agent_id, :dhcp_fingerprint_id, :dhcp_vendor_id, :device_id, :user_agent_value, :dhcp_fingerprint_value, :dhcp_vendor_value, :mac_value)
    end

end
