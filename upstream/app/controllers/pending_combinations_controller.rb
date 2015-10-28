class PendingCombinationsController < ApplicationController
  before_action :set_pending_combination, only: [:show, :approve, :decline]
  def index
    @pending_combinations = PendingCombination.all.paginate(:page => params[:page])
  end

  def show
  end

  def approve
    @pending_combination.combination.update(:device => @pending_combination.new_device, :version => @pending_combination.new_version)
    @pending_combination.update(:completed => true)
    flash.now[:success] = "Change has been approved"
    render 'show'
  end

  def decline
    @pending_combination.update(:completed => true)
    flash.now[:notice] = "Change has been declined"
    render 'show'
  end

  private
    def set_pending_combination
      @pending_combination = PendingCombination.find(params[:id])
    end
end
