require 'spec_helper'

describe TimetablesController do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #new' do
    before { get :new }

    it 'renders the new template' do
      response.should render_template('timetables/new')
    end

    it 'initializes @timetable' do
      assigns(:timetable).should be_new_record
    end
  end

  describe 'GET #index' do
    before { get :index }

    it 'renders the index template' do
      response.should render_template('timetables/index')
    end
  end

  describe 'DELETE #destroy' do
    let(:timetable) { FactoryGirl.create(:timetable) }

    context 'successful destroy' do
      before do
        Timetable.any_instance.expects(:destroy).returns(true)
        delete :destroy, :id => timetable.to_param
      end

      it 'sets flash[:success]' do
        flash[:success].should == controller.t('timetable_deleted')
      end

      it 'redirects to timetable page' do
        response.should redirect_to assigns(:timetable)
      end
    end
  end

  describe 'GET #edit' do
    let(:timetable) { FactoryGirl.create(:timetable) }

    before { get :edit, :id => timetable.to_param }

    it 'renders the edit template' do
      response.should render_template('timetables/edit')
    end

    it 'assigns @timetable' do
      assigns(:timetable).should == timetable
    end
  end

  describe 'PUT #update' do
    let(:timetable) { FactoryGirl.create(:timetable) }

    context 'successful update' do
      before do
        Timetable.any_instance.expects(:save).returns(true)
        put :update, :id => timetable.to_param, :timetable => { :start_date => '2013/02/05', :end_date => '2013/05/05' }
      end

      it 'sets flash[:success]' do
        flash[:success].should == controller.t('timetable_updated')
      end

      context 'end_date after today' do
        let(:timetable) { FactoryGirl.create(:timetable, :end_date => Date.tomorrow) }

        it 'redirects to new timetable_entry page' do
          response.should redirect_to new_timetable_timetable_entry_path(assigns(:timetable))
        end
      end

      context 'end_date before today' do
        let(:timetable) { FactoryGirl.create(:timetable, :end_date => Date.yesterday) }

        it 'redirects to timetables page' do
          response.should redirect_to timetables_path
        end
      end
    end

    context 'failed update' do
      before do
        Timetable.any_instance.expects(:save).returns(false)
        put :update, :id => timetable.to_param, :timetable => { :start_date => '2013/02/05', :end_date => '2013/05/05' }
      end

      it 'renders the edit template' do
        response.should render_template('timetables/edit')
      end
    end
  end

  describe 'POST #create' do
    context 'successful create' do
      before do
        Timetable.any_instance.expects(:save).returns(true)
        post :create, :timetable => { :start_date => '2013/02/05', :end_date => '2013/05/05' }
      end

      it 'sets flash[:success]' do
        flash[:success].should == "#{controller.t('timetable_created_from')} #{assigns(:timetable).start_date} - #{assigns(:timetable).end_date}"
      end

      it 'redirects to new timetable_entry page' do
        response.should redirect_to new_timetable_timetable_entry_path(assigns(:timetable))
      end
    end

    context 'failed create' do
      before do
        Timetable.any_instance.expects(:save).returns(false)
        post :create, :timetable => { :start_date => '2013/02/05', :end_date => '2013/05/05' }
      end

      it 'renders the new template' do
        response.should render_template('timetables/new')
      end
    end
  end

end