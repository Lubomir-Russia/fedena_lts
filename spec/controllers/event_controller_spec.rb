require 'spec_helper'

describe EventController do
  before do
    @batch = FactoryGirl.build(:batch)
    @event = FactoryGirl.create(:event)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'POST #index' do
    before do
      Event.stub(:new).and_return(@event)
    end

    context 'successful create' do
      before do
        Event.any_instance.expects(:valid?).returns(true)
        post :index, :events => {}, :id => Time.new(2013,1,1,0,0,0)
      end

      it 'assigns @date' do
        assigns(:date).should == Time.new(2013,1,1,0,0,0)
      end

      it 'redirects to show action' do
        response.should redirect_to(:action => 'show', :id => @event.id)
      end
    end

    context 'failed create' do
      before do
        Event.any_instance.expects(:valid?).returns(false)
        post :index, :events => {:start_date => Date.new(2013,1,1), :end_date => Date.new(2013,2,1)}
      end

      it 'assigns @start_date' do
        assigns(:start_date).should == Date.new(2013,1,1)
      end

      it 'assigns @end_date' do
        assigns(:end_date).should == Date.new(2013,2,1)
      end
    end
  end

  describe 'GET #event_group' do
    before do
      Event.stub(:find).and_return(@event)
      get :event_group
    end

    it 'assigns @event' do
      assigns(:event).should == @event
    end

    it 'renders the event_group template' do
      response.should render_template('event_group')
    end
  end

  describe 'GET #select_course' do
    before do
      @course = FactoryGirl.build(:course)
      @batch.course = @course
      Batch.stub(:active).and_return([@batch])
      get :select_course, :id => 1
    end

    it 'assigns @event_id' do
      assigns(:event_id).should == '1'
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'replaces element select-option with partial template' do
      response.should have_rjs(:replace_html, 'select-option')
      response.should render_template(:partial => 'select_course')
    end
  end

  describe 'POST #course_event' do
    before do
      Event.stub(:find).and_return(@event)
      BatchEvent.stub(:find_by_event_id_and_batch_id).and_return(nil)
      post :course_event, :select_options => {:batch_id => [5]}
    end

    it 'creates BatchEvent' do
      BatchEvent.first(:conditions => {:event_id => @event.id, :batch_id => 5}).should be_present
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash1')}"
    end

    it 'redirects to show action' do
      response.should redirect_to(:action => 'show', :id => @event.id)
    end
  end

  describe 'GET #remove_batch' do
    before do
      @batch_event = FactoryGirl.build(:batch_event, :event_id => @event.id)
      BatchEvent.stub(:find).and_return(@batch_event)
      @batch_event.should_receive(:delete)
      get :remove_batch
    end

    it 'assigns @batch_event' do
      assigns(:batch_event).should == @batch_event
    end

    it 'assigns @event' do
      assigns(:event).should == @event.id
    end

    it 'redirects to show action' do
      response.should redirect_to(:action => 'show', :id => @event)
    end
  end

  describe 'GET #select_employee_department' do
    before do
      @employee_department = FactoryGirl.build(:employee_department)
      EmployeeDepartment.stub(:find).and_return([@employee_department])
      get :select_employee_department, :id => 1
    end

    it 'assigns @event_id' do
      assigns(:event_id).should == '1'
    end

    it 'assigns @employee_department' do
      assigns(:employee_department).should == [@employee_department]
    end

    it 'replaces element select-options with partial template' do
      response.should have_rjs(:replace_html, 'select-options')
      response.should render_template(:partial => 'select_employee_department')
    end
  end

  describe 'POST #department_event' do
    before do
      Event.stub(:find).and_return(@event)
      EmployeeDepartmentEvent.stub(:find_by_event_id_and_employee_department_id).and_return(nil)
      post :department_event, :select_options => {:department_id => [5]}
    end

    it 'create EmployeeDepartmentEvent' do
      EmployeeDepartmentEvent.first(:conditions => {:event_id => @event.id, :employee_department_id => 5}).should be_present
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash2')}"
    end

    it 'redirects to show action' do
      response.should redirect_to(:action => 'show', :id => @event.id)
    end
  end

  describe 'GET #remove_department' do
    before do
      @employee_department_event = FactoryGirl.build(:employee_department_event, :event_id => 2)
      @employee_department_event.should_receive(:delete)
      EmployeeDepartmentEvent.stub(:find).and_return(@employee_department_event)
      get :remove_department
    end

    it 'assigns @department_event' do
      assigns(:department_event).should == @employee_department_event
    end

    it 'assigns @event' do
      assigns(:event).should == 2
    end

    it 'redirects to show action' do
      response.should redirect_to(:action => 'show', :id => 2)
    end
  end

  describe 'GET #show' do
    before do
      @event.is_common = false
      Event.stub(:find).and_return(@event)
      Event.stub(:all).and_return([@event])
      @batch_event = FactoryGirl.build(:batch_event)
      BatchEvent.stub(:all).and_return([@batch_event])
      @employee_department_event = FactoryGirl.build(:employee_department_event)
      EmployeeDepartmentEvent.stub(:all).and_return([@employee_department_event])
      get :show, :cmd => 'cmd_cmd'
    end

    it 'assigns @event' do
      assigns(:event).should == @event
    end

    it 'assigns @command' do
      assigns(:command).should == 'cmd_cmd'
    end

    it 'assigns @other_events' do
      assigns(:other_events).should == [@event]
    end

    it 'assigns @batch_events' do
      assigns(:batch_events).should == [@batch_event]
    end

    it 'assigns @department_event' do
      assigns(:department_event).should == [@employee_department_event]
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end

  describe 'POST #confirm_event' do
    before do
      Event.stub(:find).and_return(@event)
      @student = FactoryGirl.build(:student)
    end

    context 'event.is_common is true' do
      before do
        @event.is_common = true
        @event.is_holiday = true
        @period_entry = FactoryGirl.build(:period_entry)
        PeriodEntry.stub(:all).and_return([@period_entry])
        @period_entry.should_receive(:delete)
      end

      context 'sms_setting.application_sms_active && sms_setting.event_news_sms_active are true' do
        before do
          SmsSetting.any_instance.expects(:application_sms_active).returns(true)
          SmsSetting.any_instance.expects(:event_news_sms_active).returns(true)
        end

        context 'u.student == true' do
          before do
            @user.update_attributes({:student => true})
            User.any_instance.expects(:student_record).returns(@student)
          end

          context 'student.is_sms_enabled is true' do
            before { @student.stub(:is_sms_enabled).and_return(true) }

            context 'sms_setting.student_sms_active && student.phone2 are present' do
              before do
                SmsSetting.any_instance.expects(:student_sms_active).returns(true)
                @student.phone2 = '88888'
              end

              context 'sms_setting.parent_sms_active && guardian && guardian.mobile_phone are present' do
                before do
                  SmsSetting.any_instance.expects(:parent_sms_active).returns(true)
                  @guardian = FactoryGirl.build(:guardian, :ward => nil, :mobile_phone => '99999')
                  @student.stub(:immediate_contact).and_return(@guardian)
                  post :confirm_event
                end

                it 'creates Delayed::Job - SmsManager' do
                  Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
                end

                it 'creates Delayed::Job - DelayedReminderJob' do
                  Delayed::Job.last.handler.should include_text('--- !ruby/object:DelayedReminderJob')
                end

                it 'runs two Delayed::Job. SmsManager and DelayedReminderJob' do
                  Delayed::Worker.new.work_off.should == [2, 0]
                end

                it 'redirects to index calendar' do
                  response.should redirect_to(:controller =>'calendar',:action => 'index')
                end
              end
            end
          end
        end
      end
    end

    context 'event.is_common is false' do
      before do
        @event.is_common = false
        @event.is_holiday = true
        @batch_event = FactoryGirl.build(:batch_event)
        BatchEvent.stub(:find_all_by_event_id).and_return([@batch_event])
        @period_entry = FactoryGirl.build(:period_entry)
        PeriodEntry.stub(:find_all_by_batch_id).and_return([@period_entry])
        @period_entry.should_receive(:delete)

        Student.stub(:all).and_return([@student])
      end

      context 'sms_setting.application_sms_active && sms_setting.event_news_sms_active are true' do
        before do
          SmsSetting.any_instance.expects(:application_sms_active).twice.returns(true)
          SmsSetting.any_instance.expects(:event_news_sms_active).twice.returns(true)
        end

        context 's.is_sms_enabled is true' do
          before { @student.is_sms_enabled = true }

          context 'sms_setting.student_sms_active && s.phone2.present?' do
            before do
              SmsSetting.any_instance.expects(:student_sms_active).returns(true)
              @student.phone2 = '8888'
            end

            context 'sms_setting.parent_sms_active && guardian.present? && guardian.mobile_phone.present?' do
              before do
                SmsSetting.any_instance.expects(:parent_sms_active).returns(true)
                @guardian = FactoryGirl.build(:guardian, :ward => nil, :mobile_phone => '99999')
                @student.stub(:immediate_contact).and_return(@guardian)

                @employee_department_event = FactoryGirl.build(:employee_department_event)
                EmployeeDepartmentEvent.stub(:find_all_by_event_id).and_return([@employee_department_event])
                @employee = FactoryGirl.build(:employee)
                Employee.stub(:all).and_return([@employee])
              end

              context 'sms_setting.employee_sms_active is true' do
                before do
                  SmsSetting.any_instance.expects(:employee_sms_active).returns(true)
                  @employee.mobile_phone = '7777'
                  post :confirm_event
                end

                it 'creates Delayed::Job - SmsManager' do
                  Delayed::Job.first.handler.should include_text('--- !ruby/object:SmsManager')
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'DELETE #cancel_event' do
    before do
      Event.stub(:find).and_return(@event)
      @batch_event = FactoryGirl.build(:batch_event)
      BatchEvent.stub(:all).and_return([@batch_event])
      @employee_department_event = FactoryGirl.build(:employee_department_event)
      EmployeeDepartmentEvent.stub(:all).and_return([@employee_department_event])
    end

    it 'destroys event' do
      @event.should_receive(:destroy)
      delete :cancel_event
    end

    it 'destroys batch_event' do
      @batch_event.should_receive(:destroy)
      delete :cancel_event
    end

    it 'destroys dept_event' do
      @employee_department_event.should_receive(:destroy)
      delete :cancel_event
    end

    context 'DELETE #cancel_event' do
      before { delete :cancel_event }

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash3')}"
      end

      it 'redirects to index action' do
        response.should redirect_to(:action => 'index')
      end
    end
  end

  describe 'POST #edit_event' do
    before do
      Event.stub(:find_by_id).and_return(@event)
      Event.any_instance.expects(:update_attributes).returns(true)
      post :edit_event
    end

    it 'redirects to index action' do
      response.should redirect_to(:action => 'show', :id => @event.id, :cmd => 'edit')
    end
  end
end