require 'spec_helper'

describe TimetablesController do
  before do
    @user = Factory.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #new' do
    before { get :new }

    it 'renders the new template' do
      response.should render_template('timetables/new')
    end
  end

  describe 'POST #create' do
    context 'successful save' do
      before do
        Timetable.any_instance.expects(:save).returns(true)
        post :create, timetable: {}
      end

      it 'sets flash[:success]' do
        flash[:success].should == "#{controller.t('timetable_created_from')} #{assigns(:timetable).start_date} - #{assigns(:timetable).end_date}"
      end

      it 'redirects to timetable_entries/new' do
        response.should redirect_to(new_timetable_timetable_entry_path(assigns(:timetable)))
      end
    end

    context 'failed save' do
      before do
        Timetable.any_instance.expects(:save).returns(false)
        post :create, timetable: {}
      end

      it 'renders the new template' do
        response.should render_template('timetables/new')
      end
    end
  end
end