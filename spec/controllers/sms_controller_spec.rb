require 'spec_helper'

describe SmsController do
  before do
    @batch = FactoryGirl.build(:batch)
    @sms_setting = FactoryGirl.create(:sms_setting)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      SmsSetting.stub(:find_by_settings_key).with('ParentSmsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('StudentSmsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('EmployeeSmsEnabled').and_return(@sms_setting)
      get :index
    end

    it 'assigns @sms_setting' do
      assigns(:sms_setting).should be_new_record
    end

    it 'assigns @parents_sms_enabled' do
      assigns(:parents_sms_enabled).should == @sms_setting
    end

    it 'assigns @sms_setting' do
      assigns(:students_sms_enabled).should == @sms_setting
    end

    it 'assigns @sms_setting' do
      assigns(:employees_sms_enabled).should == @sms_setting
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'POST #settings' do
    before do
      @sms_setting.is_enabled = false
      SmsSetting.stub(:find_by_settings_key).with('ApplicationEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('StudentAdmissionEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('ExamScheduleResultEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('AttendanceEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('NewsEventsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('ParentSmsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('StudentSmsEnabled').and_return(@sms_setting)
      SmsSetting.stub(:find_by_settings_key).with('EmployeeSmsEnabled').and_return(@sms_setting)
    end

    context 'with Post Request' do
      before { post :settings, :sms_settings => {:application_enabled => true} }

      it 'assigns @application_sms_enabled' do
        assigns(:application_sms_enabled).should == @sms_setting
      end

      it 'assigns @student_admission_sms_enabled' do
        assigns(:student_admission_sms_enabled).should == @sms_setting
      end

      it 'assigns @exam_schedule_result_sms_enabled' do
        assigns(:exam_schedule_result_sms_enabled).should == @sms_setting
      end

      it 'assigns @student_attendance_sms_enabled' do
        assigns(:student_attendance_sms_enabled).should == @sms_setting
      end

      it 'assigns @news_events_sms_enabled' do
        assigns(:news_events_sms_enabled).should == @sms_setting
      end

      it 'assigns @parents_sms_enabled' do
        assigns(:parents_sms_enabled).should == @sms_setting
      end

      it 'assigns @students_sms_enabled' do
        assigns(:students_sms_enabled).should == @sms_setting
      end

      it 'assigns @employees_sms_enabled' do
        assigns(:employees_sms_enabled).should == @sms_setting
      end

      it 'updates @application_sms_enabled.is_enabled with params' do
        SmsSetting.find(assigns(:application_sms_enabled)).should be_is_enabled
      end

      it 'redirects to settings action' do
        response.should redirect_to(:action => 'settings')
      end
    end

    context 'with Get Request' do
      before { get :settings }

      it 'renders the settings template' do
        response.should render_template('settings')
      end
    end
  end

  describe 'POST #update_general_sms_settings' do
    before do
      @student_admission_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'StudentAdmissionEnabled', :is_enabled => false)
      @exam_schedule_result_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'ExamScheduleResultEnabled', :is_enabled => false)
      @student_attendance_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'AttendanceEnabled', :is_enabled => false)
      @news_events_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'NewsEventsEnabled', :is_enabled => false)
      @parents_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'ParentSmsEnabled', :is_enabled => false)
      @students_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'StudentSmsEnabled', :is_enabled => false)
      @employees_sms_enabled = FactoryGirl.create(:sms_setting, :settings_key => 'EmployeeSmsEnabled', :is_enabled => false)
      params = { :student_admission_enabled => true, :exam_schedule_result_enabled => true, :student_attendance_enabled => true,
        :news_events_enabled => true, :sms_parents_enabled => true, :sms_students_enabled => true, :sms_employees_enabled => true }
      post :update_general_sms_settings, :general_settings => params
    end

    it 'assigns @student_admission_sms_enabled' do
      assigns(:student_admission_sms_enabled).should == @student_admission_sms_enabled
    end

    it 'assigns @exam_schedule_result_sms_enabled' do
      assigns(:exam_schedule_result_sms_enabled).should == @exam_schedule_result_sms_enabled
    end

    it 'assigns @student_attendance_sms_enabled' do
      assigns(:student_attendance_sms_enabled).should == @student_attendance_sms_enabled
    end

    it 'assigns @news_events_sms_enabled' do
      assigns(:news_events_sms_enabled).should == @news_events_sms_enabled
    end

    it 'assigns @parents_sms_enabled' do
      assigns(:parents_sms_enabled).should == @parents_sms_enabled
    end

    it 'assigns @students_sms_enabled' do
      assigns(:students_sms_enabled).should == @students_sms_enabled
    end

    it 'assigns @employees_sms_enabled' do
      assigns(:employees_sms_enabled).should == @employees_sms_enabled
    end

    it 'updates @student_admission_sms_enabled.is_enabled with param' do
      SmsSetting.find(@student_admission_sms_enabled).should be_is_enabled
    end

    it 'updates @exam_schedule_result_sms_enabled.is_enabled with param' do
      SmsSetting.find(@exam_schedule_result_sms_enabled).should be_is_enabled
    end

    it 'updates @student_attendance_sms_enabled.is_enabled with param' do
      SmsSetting.find(@student_attendance_sms_enabled).should be_is_enabled
    end

    it 'updates @news_events_sms_enabled.is_enabled with param' do
      SmsSetting.find(@news_events_sms_enabled).should be_is_enabled
    end

    it 'updates @parents_sms_enabled.is_enabled with param' do
      SmsSetting.find(@parents_sms_enabled).should be_is_enabled
    end

    it 'updates @students_sms_enabled.is_enabled with param' do
      SmsSetting.find(@students_sms_enabled).should be_is_enabled
    end

    it 'updates @employees_sms_enabled.is_enabled with param' do
      SmsSetting.find(@employees_sms_enabled).should be_is_enabled
    end

    it 'redirects to settings action' do
      response.should redirect_to(:action => 'settings')
    end
  end

  describe 'POST #students' do
    before do
      @guardian = FactoryGirl.build(:guardian, :mobile_phone => '8888')
      @student = FactoryGirl.build(:student, :phone2 => '9999')
      @student.stub(:immediate_contact).and_return(@guardian)
      Student.stub(:find).and_return(@student)
    end

    context 'student.is_sms_enabled is true' do
      before { @student.stub(:is_sms_enabled).and_return(true) }

      context 'sms_setting.student_sms_active and sms_setting.parent_sms_active are true' do
        before do
          SmsSetting.any_instance.expects(:student_sms_active).returns(true)
          SmsSetting.any_instance.expects(:parent_sms_active).returns(true)
          post :students, :send_sms => {:student_ids => [1], :message => 'Test Message'}
        end

        it 'assigns @recipients' do
          assigns(:recipients).should == ['9999', '8888']
        end

        it 'creates Delayed::Job SmsManager' do
          Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
          Delayed::Worker.new.work_off.should == [1, 0]
        end

        it 'replaces element status-message with text' do
          response.should have_rjs(:replace_html, 'status-message')
          response.should include_text("<p class=\\\"flash-msg\\\">#{I18n.t('sms_sending_intiated', :log_url => '/sms/show_sms_messages')}</p>")
        end

        it 'adds effect highlight' do
          response.should include_text("new Effect.Highlight(\"status-message\",{});")
        end
      end
    end
  end

  describe 'GET #list_students' do
    before do
      Batch.stub(:find).and_return(@batch)
      @student = FactoryGirl.build(:student)
      Student.stub(:find_all_by_batch_id).and_return([@student])
      get :list_students
    end

    it 'assigns @students' do
      assigns(:students).should == [@student]
    end

    it 'renders the list_students template' do
      response.should render_template('list_students')
    end
  end

  describe 'POST #batches' do
    before do
      Batch.stub(:active).and_return([@batch])
      @student = FactoryGirl.build(:student, :phone2 => '8888')
      @batch.stub(:students).and_return([@student])
      Batch.stub(:find).and_return(@batch)
    end

    context 'student.is_sms_enabled is true' do
      before { @student.stub(:is_sms_enabled).and_return(true) }

      context 'sms_setting.student_sms_active and sms_setting.parent_sms_active are true' do
        before do
          SmsSetting.any_instance.expects(:student_sms_active).returns(true)
          SmsSetting.any_instance.expects(:parent_sms_active).returns(true)
          @guardian = FactoryGirl.build(:guardian, :mobile_phone => '9999')
          @student.stub(:immediate_contact).and_return(@guardian)
          post :batches, :send_sms => {:batch_ids => [1], :message => 'Test Message'}
        end

        it 'assigns @recipients' do
          assigns(:recipients).should == ['8888', '9999']
        end

        it 'creates Delayed::Job SmsManager' do
          Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
          Delayed::Worker.new.work_off.should == [1, 0]
        end

        it 'replaces element status-message with text' do
          response.should have_rjs(:replace_html, 'status-message')
          response.should include_text("<p class=\\\"flash-msg\\\">#{I18n.t('sms_sending_intiated', :log_url => '/sms/show_sms_messages')}</p>")
        end

        it 'adds effect highlight' do
          response.should include_text("new Effect.Highlight(\"status-message\",{});")
        end
      end
    end
  end

  describe 'POST #sms_all' do
    before do
      Batch.stub(:active).and_return([@batch])
      @student = FactoryGirl.build(:student, :phone2 => '8888')
      @batch.stub(:students).and_return([@student])
    end

    context 'student.is_sms_enabled is true' do
      before { @student.is_sms_enabled = true }

      context 'sms_setting.student_sms_active and sms_setting.parent_sms_active are true' do
        before do
          SmsSetting.any_instance.expects(:student_sms_active).returns(true)
          SmsSetting.any_instance.expects(:parent_sms_active).returns(true)
          @guardian = FactoryGirl.build(:guardian, :mobile_phone => '9999')
          @student.stub(:immediate_contact).and_return(@guardian)
        end

        context 'sms_setting.employee_sms_active is true' do
          before do
            SmsSetting.any_instance.expects(:employee_sms_active).returns(true)
            @employee_department = FactoryGirl.build(:employee_department)
            EmployeeDepartment.stub(:all).and_return([@employee_department])
            @employee = FactoryGirl.build(:employee, :mobile_phone => '7777')
            @employee_department.stub(:employees).and_return([@employee])
            post :sms_all, :send_sms => {:message => 'Test Message'}
          end

          it 'assigns @recipients' do
            assigns(:recipients).should == ['8888', '9999', '7777']
          end

          it 'creates Delayed::Job SmsManager' do
            Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
            Delayed::Worker.new.work_off.should == [1, 0]
          end

          it 'replaces element status-message with text' do
            response.should have_rjs(:replace_html, 'status-message')
            response.should include_text("<p class=\\\"flash-msg\\\">#{I18n.t('sms_sending_intiated', :log_url => '/sms/show_sms_messages')}</p>")
          end

          it 'adds effect highlight' do
            response.should include_text("new Effect.Highlight(\"status-message\",{});")
          end
        end
      end
    end
  end

  describe 'POST #employees' do
    before do
      @employee = FactoryGirl.build(:employee, :mobile_phone => '9999')
      Employee.stub(:find).and_return(@employee)
    end

    context 'sms_setting.employee_sms_active is true' do
      before do
        SmsSetting.any_instance.expects(:employee_sms_active).returns(true)
        post :employees, :send_sms => {:employee_ids => [1], :message => 'Test Message'}
      end

      it 'assigns @recipients' do
        assigns(:recipients).should == ['9999']
      end

      it 'creates Delayed::Job SmsManager' do
        Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
        Delayed::Worker.new.work_off.should == [1, 0]
      end

      it 'replaces element status-message with text' do
        response.should have_rjs(:replace_html, 'status-message')
        response.should include_text("<p class=\\\"flash-msg\\\">#{I18n.t('sms_sending_intiated', :log_url => '/sms/show_sms_messages')}</p>")
      end

      it 'adds effect highlight' do
        response.should include_text("new Effect.Highlight(\"status-message\",{});")
      end
    end
  end

  describe 'GET #list_employees' do
    before do
      @employee_department = FactoryGirl.build(:employee_department)
      EmployeeDepartment.stub(:find).and_return(@employee_department)
      @employee = FactoryGirl.build(:employee)
      @employee_department.stub(:employees).and_return([@employee])
      get :list_employees
    end

    it 'assigns @employees' do
      assigns(:employees).should == [@employee]
    end

    it 'renders the list_employees template' do
      response.should render_template('list_employees')
    end
  end

  describe 'POST #departments' do
    before do
      @employee_department = FactoryGirl.build(:employee_department)
      EmployeeDepartment.stub(:all).and_return([@employee_department])
      EmployeeDepartment.stub(:find).and_return(@employee_department)
      @employee = FactoryGirl.build(:employee, :mobile_phone => '9999')
      @employee_department.stub(:employees).and_return([@employee])
      SmsSetting.any_instance.expects(:employee_sms_active).returns(true)
      post :departments, :send_sms => {:dept_ids => [1], :message => 'Test Message'}
    end

    it 'assigns @recipients' do
      assigns(:recipients).should == ['9999']
    end

    it 'creates Delayed::Job SmsManager' do
      Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
      Delayed::Worker.new.work_off.should == [1, 0]
    end

    it 'replaces element status-message with text' do
      response.should have_rjs(:replace_html, 'status-message')
      response.should include_text("<p class=\\\"flash-msg\\\">#{I18n.t('sms_sending_intiated', :log_url => '/sms/show_sms_messages')}</p>")
    end

    it 'adds effect highlight' do
      response.should include_text("new Effect.Highlight(\"status-message\",{});")
    end
  end

  describe 'GET #show_sms_messages' do
    before do
      @sms_message = FactoryGirl.build(:sms_message)
      @configuration = FactoryGirl.build(:configuration)
      SmsMessage.stub(:get_sms_messages).and_return([@sms_message])
      Configuration.stub(:get_config_value).and_return(@configuration)
      get :show_sms_messages
    end

    it 'assigns @sms_messages' do
      assigns(:sms_messages).should == [@sms_message]
    end

    it 'assigns @total_sms' do
      assigns(:total_sms).should == @configuration
    end

    it 'renders the show_sms_messages template' do
      response.should render_template('show_sms_messages')
    end
  end

  describe 'GET #show_sms_logs' do
    before do
      @sms_message = FactoryGirl.build(:sms_message)
      SmsMessage.stub(:find).and_return(@sms_message)
      @sms_log = FactoryGirl.build(:sms_log)
      @sms_message.stub(:get_sms_logs).and_return([@sms_log])
      get :show_sms_logs
    end

    it 'assigns @sms_message' do
      assigns(:sms_message).should == @sms_message
    end

    it 'assigns @sms_logs' do
      assigns(:sms_logs).should == [@sms_log]
    end

    it 'renders the show_sms_logs template' do
      response.should render_template('show_sms_logs')
    end
  end
end
