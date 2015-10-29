class PendingCombinationsController < ApplicationController
  before_action :set_pending_combination, only: [:show, :approve, :decline]
  before_filter :check_if_completed, only: [:approve, :decline]

  def index
    if params[:all]
      @pending_combinations = PendingCombination.all
    else
      @pending_combinations = PendingCombination.where(:completed => false)
    end
    @pending_combinations = @pending_combinations.order('created_at DESC').paginate(:page => params[:page])
  end

  def show
  end

  def approve
    UserMailer.pending_combination_approved(@pending_combination).deliver_later
    @pending_combination.combination.update(:device => @pending_combination.new_device, :version => @pending_combination.new_version, :fixed => true)
    @pending_combination.update(:completed => true)
    flash.now[:success] = "Change has been approved"
    render 'show'
  end

  def decline
    UserMailer.pending_combination_declined(@pending_combination, params[:reason]).deliver_later
    @pending_combination.update(:completed => true)
    flash.now[:notice] = "Change has been declined"
    render 'show'
  end

  private
    def set_pending_combination
      @pending_combination = PendingCombination.find(params[:id])
    end

    def check_if_completed
      if @pending_combination.completed
        flash.now[:error] = "This request has already been processed"
        redirect_to :back
      end
    end
end
