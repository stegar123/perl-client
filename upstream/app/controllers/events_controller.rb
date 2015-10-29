class EventsController < ApplicationController
  def index
    @events = Event.all.limit(50).order('created_at DESC').paginate(:page => params[:page], :per_page => 10)

    @events.each do |event|
      event.value = event.value ? event.value.gsub(/\n/, '<br>') : ""
    end

    respond_to do |format|
      format.rss { render :layout => false }
      format.html
    end
  end
end
