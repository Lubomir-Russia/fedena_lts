require 'spec_helper'

describe SmsSettingsController do
  before do
    @sms_setting  = FactoryGirl.create(:sms_setting)
    @user       = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      SmsSetting.stub(:find_by_settings_key).with('ApplicationEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('StudentAdmissionEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('ExamScheduleEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('ResultPublishEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('AttendanceEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('NewsEventsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('ParentSmsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('StudentSmsEnabled').and_return(@sms_setting)
    end

    context 'when get request' do
      before { get :index }

      it 'renders the index template' do
        response.should render_template('index')
      end

      it 'assigns SmsSetting key ApplicationEnabled as @application_sms_enabled' do
        assigns(:application_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key StudentAdmissionEnabled as @student_admission_sms_enabled' do
        assigns(:student_admission_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key ExamScheduleEnabled as @exam_schedule_sms_enabled' do
        assigns(:exam_schedule_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key ResultPublishEnabled as @result_publish_sms_enabled' do
        assigns(:result_publish_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key AttendanceEnabled as @student_attendance_sms_enabled' do
        assigns(:student_attendance_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key NewsEventsEnabled as @news_events_sms_enabled' do
        assigns(:news_events_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key ParentSmsEnabled as @parents_sms_enabled' do
        assigns(:parents_sms_enabled).should == @sms_setting
      end

      it 'assigns SmsSetting key StudentSmsEnabled as @students_sms_enabled' do
        assigns(:students_sms_enabled).should == @sms_setting
      end
    end

    context 'post requrest with argument' do
      before { post :index, :sms_settings => { :application_enabled => true } }

      it 'does update @application_sms_enabled is_enabled with param' do
        SmsSetting.find(@sms_setting).should be_is_enabled
      end

      it 'redirects to the action index' do
        response.should redirect_to(:action => "index")
      end
    end
  end

  describe 'GET #update_general_sms_settings' do
    before do
      @student_admission_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'StudentAdmissionEnabled', :is_enabled =>  false)
      @exam_schedule_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'ExamScheduleEnabled', :is_enabled =>  false)
      @result_publish_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'ResultPublishEnabled', :is_enabled =>  false)
      @student_attendance_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'AttendanceEnabled', :is_enabled =>  false)
      @news_events_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'NewsEventsEnabled', :is_enabled =>  false)
      @parents_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'ParentSmsEnabled', :is_enabled =>  false)
      @students_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'StudentSmsEnabled', :is_enabled =>  false)
      post :update_general_sms_settings, :general_settings => {
        :student_admission_enabled => true,
        :exam_schedule_enabled => true,
        :result_publish_enabled => true,
        :student_attendance_enabled => true,
        :news_events_enabled => true,
        :sms_parents_enabled => true,
        :sms_students_enabled => true
      }
    end

    it 'assigns SmsSetting key StudentAdmissionEnabled as @student_admission_sms_enabled' do
      assigns(:student_admission_sms_enabled).should == @student_admission_sms_enabled
    end

    it 'assigns SmsSetting key ExamScheduleEnabled as @exam_schedule_sms_enabled' do
      assigns(:exam_schedule_sms_enabled).should == @exam_schedule_sms_enabled
    end

    it 'assigns SmsSetting key ResultPublishEnabled as @result_publish_sms_enabled' do
      assigns(:result_publish_sms_enabled).should == @result_publish_sms_enabled
    end

    it 'assigns SmsSetting key AttendanceEnabled as @student_attendance_sms_enabled' do
      assigns(:student_attendance_sms_enabled).should == @student_attendance_sms_enabled
    end

    it 'assigns SmsSetting key NewsEventsEnabled as @news_events_sms_enabled' do
      assigns(:news_events_sms_enabled).should == @news_events_sms_enabled
    end

    it 'assigns SmsSetting key ParentSmsEnabled as @parents_sms_enabled' do
      assigns(:parents_sms_enabled).should == @parents_sms_enabled
    end

    it 'assigns SmsSetting key StudentSmsEnabled as @students_sms_enabled' do
      assigns(:students_sms_enabled).should == @students_sms_enabled
    end

    it 'does update student_admission_sms_enabled.is_enabled with param' do
      SmsSetting.find(@student_admission_sms_enabled).should be_is_enabled
    end

    it 'does update exam_schedule_sms_enabled.is_enabled with param' do
      SmsSetting.find(@exam_schedule_sms_enabled).should be_is_enabled
    end

    it 'does update result_publish_sms_enabled.is_enabled with param' do
      SmsSetting.find(@result_publish_sms_enabled).should be_is_enabled
    end

    it 'does update student_attendance_sms_enabled.is_enabled with param' do
      SmsSetting.find(@student_attendance_sms_enabled).should be_is_enabled
    end

    it 'does update news_events_sms_enabled.is_enabled with param' do
      SmsSetting.find(@news_events_sms_enabled).should be_is_enabled
    end

    it 'does update parents_sms_enabled.is_enabled with param' do
      SmsSetting.find(@parents_sms_enabled).should be_is_enabled
    end

    it 'does update students_sms_enabled.is_enabled with param' do
      SmsSetting.find(@students_sms_enabled).should be_is_enabled
    end

    it 'redirects to the action index' do
      response.should redirect_to(:action => "index")
    end
  end
end