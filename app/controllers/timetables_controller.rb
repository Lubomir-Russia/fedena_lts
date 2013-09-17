class TimetablesController < ApplicationController
  before_filter :login_required
  before_filter :protect_other_student_data
  before_filter :default_time_zone_present_time
  filter_access_to :all

  def new
    @timetable = Timetable.new
  end

  def create
    @timetable = Timetable.new(params[:timetable])

    if @timetable.save
      flash[:success]= "#{t('timetable_created_from')} #{@timetable.start_date} - #{@timetable.end_date}"
      redirect_to new_timetable_timetable_entry_path(@timetable)
    else
      render :action => :new
    end
  end

  def index
    @courses    = Batch.active
    @timetables = Timetable.all
    # @timetables = Timetable.find(:all, :conditions => ["end_date > ?", @local_tzone_time.to_date])
  end

  def edit
    @timetable = Timetable.find(params[:id])
  end

  def destroy
    @timetable = Timetable.find(params[:id])

    if @timetable.destroy
      flash[:success] = t('timetable_deleted')
      redirect_to @timetable
    end
  end

  def update
    @timetable = Timetable.find(params[:id])
    @timetable.start_date_year  = params[:timetable][:"start_date(1i)"]
    @timetable.start_date_month = params[:timetable][:"start_date(2i)"]
    @timetable.start_date_year  = params[:timetable][:"start_date(3i)"]

    @timetable.end_date_year  = params[:timetable][:"end_date(1i)"]
    @timetable.end_date_month = params[:timetable][:"end_date(2i)"]
    @timetable.end_date_year  = params[:timetable][:"end_date(3i)"]

    if @timetable.save
      flash[:success] = t('timetable_updated')

      if @timetable.end_date > Date.today
        redirect_to new_timetable_timetable_entry_path(@timetable)
      else
        redirect_to timetables_path
      end
    else
      render :action => :edit
    end
  end

end