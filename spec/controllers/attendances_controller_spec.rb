require 'spec_helper'

describe AttendancesController do
  before do
    controller.stub!(:only_assigned_employee_allowed)
    controller.stub!(:default_time_zone_present_time)
    controller.instance_variable_set(:@local_tzone_time, Time.current)
    @configuration = FactoryGirl.build(:configuration)
    @student = FactoryGirl.build(:student)
    @subject = FactoryGirl.build(:subject)
    @attendance = FactoryGirl.build(:attendance)
    @batch = FactoryGirl.build(:batch)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      controller.stub(:current_user).and_return(@user)
      controller.stub!(:only_privileged_employee_allowed)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
    end

    context 'current_user is admin' do
      before do
        @user.stub(:admin?).and_return(true)
        Batch.stub(:active).and_return([@batch])
        get :index
      end

      it 'assigns @config' do
        assigns(:config).should == @configuration
      end

      it 'assigns @date_today' do
        assigns(:date_today).should == Time.current.to_date
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch]
      end

      it 'renders the index template' do
        response.should render_template('index')
      end
    end

    context 'current_user has StudentAttendanceRegister privilege' do
      before do
        @privilege = FactoryGirl.build(:privilege, :name => 'StudentAttendanceRegister')
        @user.stub(:admin?).and_return(false)
        @user.stub(:privileges).and_return([@privilege])
        Batch.stub(:active).and_return([@batch])
        get :index
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch]
      end
    end

    context 'current_user is employee' do
      before do
        @user.stub(:admin?).and_return(false)
        @user.stub(:employee?).and_return(true)
      end

      context '@config.config_value == Daily' do
        before do
          @configuration.config_value = 'Daily'
          @employee = FactoryGirl.build(:employee)
          @employee.stub(:employee_batches).and_return([@batch])
          @user.stub(:employee_record).and_return(@employee)
          get :index
        end

        it 'assigns @batches' do
          assigns(:batches).should == [@batch]
        end
      end

      context '@config.config_value != Daily' do
        before do
          @configuration.config_value = nil
          @employee = FactoryGirl.build(:employee)
          @batch1 = FactoryGirl.build(:batch)
          @subject.batch = @batch1
          @employee.stub(:employee_batches).and_return([@batch])
          @employee.stub(:subjects).and_return([@subject])
          @user.stub(:employee_record).and_return(@employee)
          get :index
        end

        it 'assigns @batches' do
          assigns(:batches).should == [@batch, @batch1]
        end
      end
    end
  end

  describe 'POST #list_subject' do
    context 'params[:batch_id] is present' do
      before do
        controller.stub(:current_user).and_return(@user)
        Batch.stub(:find).and_return(@batch)
      end

      context '@current_user.employee? && @allow_access && privilege.name not include "StudentAttendanceRegister"' do
        before do
          @user.stub(:employee?).and_return(true)
          controller.instance_variable_set(:@allow_access, true)
          @user.stub(:privileges).and_return([])
        end

        context '@batch.employee_id.to_i == @current_user.employee_record.id' do
          before do
            @batch.employee_id = 5
            @employee = FactoryGirl.build(:employee, :id => 5)
            @user.stub(:employee_record).and_return(@employee)
            @batch.stub(:subjects).and_return([@subject])
            post :list_subject, :batch_id => 1
          end

          it 'assigns @subjects' do
            assigns(:subjects).should == [@subject]
          end

          it 'replaces element subjects with partial template' do
            response.should have_rjs(:replace_html, 'subjects')
            response.should render_template(:partial => 'subjects')
          end
        end

        context '@batch.employee_id.to_i != @current_user.employee_record.id' do
          before do
            @batch.employee_id = 6
            @employee = FactoryGirl.build(:employee, :id => 5)
            @user.stub(:employee_record).and_return(@employee)
            Subject.stub(:all).and_return([@subject])
            post :list_subject, :batch_id => 1
          end

          it 'assigns @subjects' do
            assigns(:subjects).should == [@subject]
          end
        end
      end
    end

    context 'params[:batch_id] is nil' do
      before { post :list_subject }

      it 'replaces element register' do
        response.should have_rjs(:replace_html, 'register')
      end

      it 'replaces element subjects' do
        response.should have_rjs(:replace_html, 'subjects')
      end
    end
  end

  describe 'GET #show' do
    before { Configuration.stub(:find_by_config_key).and_return(@configuration) }

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        Batch.stub(:find).and_return(@batch)
        Student.stub(:find_all_by_batch_id).and_return([@student])
        @batch.stub(:working_days).and_return([1,2,3])
      end

      context 'params[:next] is present' do
        before { get :show, :next => Date.new(2013,7,8) }

        it 'assigns @config' do
          assigns(:config).should == @configuration
        end

        it 'assigns @today' do
          assigns(:today).should == Date.new(2013,7,8).to_date
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @students' do
          assigns(:students).should == [@student]
        end

        it 'assigns @dates' do
          assigns(:dates).should == [1, 2, 3]
        end

        it 'renders the show template' do
          response.should render_template('show')
        end
      end

      context 'params[:next] is nil' do
        before { get :show }

        it 'assigns @today' do
          assigns(:today).should == Time.current.to_date
        end
      end
    end

    context '@config.config_value != Daily' do
      before do
        @configuration.config_value = nil
        Subject.stub(:find).and_return(@subject)
        Batch.stub(:find).and_return(@batch)
        @timetable = FactoryGirl.build(:timetable)
        Timetable.stub(:tte_for_range).and_return({'4' => 'value', '7' => 'value', '11' => 'value'})
        @batch.stub(:holiday_event_dates).and_return(['7'])
      end

      context '@sub.elective_group_id is present' do
        before do
          @subject.elective_group_id = 5
          @students_subject = FactoryGirl.build(:students_subject, :student_id => 6)
          StudentsSubject.stub(:find_all_by_subject_id).and_return([@students_subject])
          Student.stub(:find_all_by_batch_id).and_return([@student])
          get :show
        end

        it 'assigns @sub' do
          assigns(:sub).should == @subject
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @students' do
          assigns(:students).should == [@student]
        end

        it 'assigns @dates' do
          assigns(:dates).should == {'4' => 'value', '7' => 'value', '11' => 'value'}
        end

        it 'assigns @dates_key' do
          assigns(:dates_key).should == ['4', '11']
        end
      end

      context '@sub.elective_group_id is present' do
        before do
          @subject.elective_group_id = nil
          Student.stub(:find_all_by_batch_id).and_return([@student])
          get :show
        end

        it 'assigns @students' do
          assigns(:students).should == [@student]
        end
      end
    end
  end

  describe 'POST #subject_wise_register' do
    context 'params[:subject_id] is present' do
      before do
        @student = FactoryGirl.create(:student)
        Subject.stub(:find).and_return(@subject)
        Batch.stub(:find).and_return(@batch)
        @subject_leave = FactoryGirl.build(:subject_leave, :student => @student, :batch => @batch, :subject => @subject)
        SubjectLeave.stub(:by_month_batch_subject).and_return([@subject_leave])

        Timetable.stub(:tte_for_range).and_return({'4' => 'value', '7' => 'value', '11' => 'value'})
        @subject_leave.class_timing_id = 7
        @subject_leave.id = 9
        @subject_leave.month_date = Date.new(2013,5,6)
      end

      context '@sub.elective_group_id is present' do
        before do
          @subject.elective_group_id = 5
          @students_subject = FactoryGirl.build(:students_subject, :student_id => 6)
          StudentsSubject.stub(:find_all_by_subject_id).and_return([@students_subject])
          @batch.students.stub(:all).and_return([@student])
        end

        context 'params[:next] is present' do
          before do
            post :subject_wise_register, :subject_id => 2, :next => Date.new(2013,7,8)
          end

          it 'assigns @sub' do
            assigns(:sub).should == @subject
          end

          it 'assigns @batch' do
            assigns(:batch).should == @batch
          end

          it 'assigns @today' do
            assigns(:today).should == Date.new(2013,7,8).to_date
          end

          it 'assigns @students' do
            assigns(:students).should == [@student]
          end

          it 'assigns @leaves' do
            assigns(:leaves).should == { @student.id => { "2013-05-06" => {7 => 9} }}
          end

          it 'assigns @dates' do
            assigns(:dates).should == {'4' => 'value', '7' => 'value', '11' => 'value'}
          end

          it 'assigns @translated' do
            trans = {"name" => "Name", "Sun" => "Sun", "Mon" => "Mon", "Tue" => "Tue", "Wed" => "Wed", "Thu" => "Thu", "Fri" => "Fri", "Sat" => "Sat",
              "January" => "January", "February" => "February", "March" => "March", "April" => "April", "May" => "May", "June" => "June", "July"=>"July",
              "August" => "August", "September" => "September", "October" => "October", "November" => "November", "December" => "December"}
            assigns(:translated).should == trans
          end

          it 'renders json' do
            @expected = {
              'leaves'      => { @student.id => { "2013-05-06" => {7 => 9} } },
              'students'    => [@student],
              'dates'       => {'4' => 'value', '7' => 'value', '11' => 'value'},
              'batch'       => @batch,
              'today'       => Date.new(2013,7,8).to_date,
              'translated'  => {"name" => "Name", "Sun" => "Sun", "Mon" => "Mon", "Tue" => "Tue", "Wed" => "Wed", "Thu" => "Thu", "Fri" => "Fri", "Sat" => "Sat",
                "January" => "January", "February" => "February", "March" => "March", "April" => "April", "May" => "May", "June" => "June", "July"=>"July",
                "August" => "August", "September" => "September", "October" => "October", "November" => "November", "December" => "December"}
            }.to_json
            response.body.should == @expected
          end
        end

        context 'params[:next] is nil' do
          before { post :subject_wise_register, :subject_id => 2 }

          it 'assigns @today' do
            assigns(:today).should == Date.current.to_date
          end
        end
      end

      context '@sub.elective_group_id is nil' do
        before do
          @subject.elective_group_id = nil
          @batch.stub(:students).and_return([@student])
          post :subject_wise_register, :subject_id => 2
        end

        it 'assigns @students' do
          assigns(:students).should == [@student]
        end
      end
    end

    context 'params[:subject_id] is nil' do
      before { post :subject_wise_register }

      it 'replaces element register' do
        response.should have_rjs(:replace_html, 'register')
      end

      it 'hides element loader' do
        response.should have_rjs(:hide, 'loader')
      end
    end
  end

  describe 'POST #daily_register' do
    before do
      Batch.stub(:find).and_return(@batch)
      @student = FactoryGirl.create(:student)
      @batch.stub(:students).and_return([@student])
      @attendance = FactoryGirl.build(:attendance, :student => @student, :batch => @batch)
      Attendance.stub(:by_month_and_batch).and_return([@attendance])
      @attendance.id = 3
      @attendance.month_date = Date.new(2013,4,5)
      @batch.stub(:working_days).and_return([1,2,3])
    end

    context 'params[:next] is present' do
      before { post :daily_register, :next => Date.new(2013,6,7) }

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @today' do
        assigns(:today).should == Date.new(2013,6,7).to_date
      end

      it 'assigns @students' do
        assigns(:students).should == [@student]
      end

      it 'assigns @leaves' do
        assigns(:leaves).should == { @student.id => { "2013-04-05" => @attendance.id } }
      end

      it 'assigns @dates' do
        assigns(:dates).should == [1, 2, 3]
      end

      it 'assigns @holidays' do
        assigns(:holidays).should == []
      end

      it 'assigns @translated' do
        trans = {"name" => "Name", "Sun" => "Sun", "Mon" => "Mon", "Tue" => "Tue", "Wed" => "Wed", "Thu" => "Thu", "Fri" => "Fri", "Sat" => "Sat",
          "January" => "January", "February" => "February", "March" => "March", "April" => "April", "May" => "May", "June" => "June", "July"=>"July",
          "August" => "August", "September" => "September", "October" => "October", "November" => "November", "December" => "December"}
        assigns(:translated).should == trans
      end

      it 'renders json' do
        @expected = {
          'leaves'      => { @student.id => { "2013-04-05" => @attendance.id } },
          'students'    => [@student],
          'dates'       => [1, 2, 3],
          'holidays'    => [],
          'batch'       => @batch,
          'today'       => Date.new(2013,6,7).to_date,
          'translated'  => {"name" => "Name", "Sun" => "Sun", "Mon" => "Mon", "Tue" => "Tue", "Wed" => "Wed", "Thu" => "Thu", "Fri" => "Fri", "Sat" => "Sat",
            "January" => "January", "February" => "February", "March" => "March", "April" => "April", "May" => "May", "June" => "June", "July"=>"July",
            "August" => "August", "September" => "September", "October" => "October", "November" => "November", "December" => "December"}
        }.to_json
        response.body.should == @expected
      end
    end

    context 'params[:next] is nil' do
      before { post :daily_register }

      it 'assigns @today' do
        assigns(:today).should == Date.current.to_date
      end
    end
  end

  describe 'GET #new' do
    before { Configuration.stub(:find_by_config_key).and_return(@configuration) }

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        Student.stub(:find).and_return(@student)
        get :new, :date => Date.new(2013,1,2)
      end

      it 'assigns @config' do
        assigns(:config).should == @configuration
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'assigns @month_date' do
        assigns(:month_date).should == Date.new(2013,1,2)
      end

      it 'assigns @absentee' do
        assigns(:absentee).should be_new_record
      end

      it 'renders the new template' do
        response.should render_template('new')
      end
    end

    context '@config.config_value != Daily' do
      before { @configuration.config_value = nil }

      context 'params[:id] is present' do
        before do
          Student.stub(:find).and_return(@student)
          get :new, :id => 1
        end

        it 'assigns @student' do
          assigns(:student).should == @student
        end
      end

      context 'params[:id] is nil && params[:subject_leave][:student_id]' do
        before do
          Student.stub(:find).and_return(@student)
          get :new, :subject_leave => {:student_id => 1}
        end

        it 'assigns @student' do
          assigns(:student).should == @student
        end
      end
    end
  end

  describe 'POST #create' do
    before { Configuration.stub(:find_by_config_key).and_return(@configuration) }

    context '@config.config_value == SubjectWise' do
      before do
        @configuration.config_value = 'SubjectWise'
        Student.stub(:find).and_return(@student)
        @timetable_entry = FactoryGirl.build(:timetable_entry, :employee_id => 10, :class_timing_id => 11)
        TimetableEntry.stub(:find).and_return(@timetable_entry)
        @subject_leave = FactoryGirl.build(:subject_leave, :student => @student, :batch => @batch, :subject => @subject)
        SubjectLeave.stub(:new).and_return(@subject_leave)
        @student.batch_id = 12
      end

      context 'successful create' do
        before do
          SubjectLeave.any_instance.expects(:save).returns(true)
          SmsSetting.any_instance.expects(:application_sms_active).returns(true)
          Student.any_instance.expects(:is_sms_enabled).returns(true)
          SmsSetting.any_instance.expects(:attendance_sms_active).returns(true)
        end

        context 'sms_setting.student_sms_active is true' do
          before do
            SmsSetting.any_instance.expects(:student_sms_active).returns(true)
            @student.phone2 = '8888'
          end

          context 'sms_setting.parent_sms_active && @student.immediate_contact_id.present?' do
            before do
              SmsSetting.any_instance.expects(:parent_sms_active).returns(true)
              @guardian = FactoryGirl.build(:guardian, :mobile_phone => '9999')
              @student.stub(:immediate_contact_id).and_return(@guardian)
              Guardian.stub(:find).and_return(@guardian)
              post :create, :subject_leave => {:student_id => 1, :subject_id => 2}
            end

            it 'assigns @config' do
              assigns(:config).should == @configuration
            end

            it 'assigns @student' do
              assigns(:student).should == @student
            end

            it 'assigns @tte' do
              assigns(:tte).should == @timetable_entry
            end

            it 'creates Delayed::Job - SmsManager' do
              handler = Delayed::Job.first.handler
              handler.should include_text('--- !ruby/object:SmsManager')
              handler.should include_text("#{@student.first_name} #{@student.last_name} #{@controller.t('flash_msg7')} #{@subject_leave.month_date}  #{@controller.t('flash_subject')} #{@subject_leave.subject.name} #{@controller.t('flash_period')} #{@subject_leave.class_timing.try(:name)}")
            end

            it 'runs Delayed::Job - SmsManager' do
              Delayed::Worker.new.work_off.should == [1, 0]
            end

            it 'renders the create template' do
              response.should render_template('create')
            end
          end
        end
      end

      context 'failed create' do
        before { SubjectLeave.any_instance.expects(:save).returns(false) }

        context 'with html format' do
          before { post :create, :subject_leave => {:student_id => 1, :subject_id => 2}, :format => 'html' }

          it 'assigns @error to true' do
            assigns(:error).should be_true
          end

          it 'renders action new in html format' do
            response.content_type.should == Mime::HTML
            response.should render_template('new')
          end
        end

        context 'with js format' do
          before { post :create, :subject_leave => {:student_id => 1, :subject_id => 2}, :format => 'js' }

          it 'renders action create in js format' do
            response.content_type.should == Mime::JS
            response.should render_template('create')
          end
        end
      end
    end

    context '@config.config_value != SubjectWise' do
      before do
        @configuration.config_value = nil
        Student.stub(:find).and_return(@student)
        @attendance = FactoryGirl.build(:attendance)
        Attendance.stub(:new).and_return(@attendance)
      end

      context 'failed create' do
        before do
          Attendance.any_instance.expects(:save).returns(false)
          post :create, :attendance => {:student_id => 1}
        end

        it 'assigns @student' do
          assigns(:student).should == @student
        end

        it 'assigns @absentee' do
          assigns(:absentee).should == @attendance
        end
      end
    end
  end

  describe 'GET #edit' do
    before do
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Student.stub(:find).and_return(@student)
    end

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        @attendance = FactoryGirl.build(:attendance)
        Attendance.stub(:find).and_return(@attendance)
        get :edit
      end

      it 'assigns @config' do
        assigns(:config).should == @configuration
      end

      it 'assigns @absentee' do
        assigns(:absentee).should == @attendance
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'renders the edit template' do
        response.should render_template('edit')
      end
    end

    context '@config.config_value != Daily' do
      before do
        @configuration.config_value = nil
        @subject_leave = FactoryGirl.build(:subject_leave)
        SubjectLeave.stub(:find).and_return(@subject_leave)
        get :edit
      end

      it 'assigns @absentee' do
        assigns(:absentee).should == @subject_leave
      end
    end
  end

  describe 'PUT #update' do
    before do
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Student.stub(:find).and_return(@student)
    end

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        @attendance = FactoryGirl.build(:attendance)
        Attendance.stub(:find).and_return(@attendance)
      end

      context 'failed update' do
        before do
          Attendance.any_instance.expects(:update_attributes).returns(false)
          put :update
        end

        it 'assigns @config' do
          assigns(:config).should == @configuration
        end

        it 'assigns @absentee' do
          assigns(:absentee).should == @attendance
        end

        it 'assigns @student' do
          assigns(:student).should == @student
        end

        it 'assigns @error to true' do
          assigns(:error).should be_true
        end

        it 'renders the update template' do
          response.should render_template('update')
        end
      end
    end

    context '@config.config_value != Daily' do
      before do
        @configuration.config_value = nil
        @subject_leave = FactoryGirl.build(:subject_leave)
        SubjectLeave.stub(:find).and_return(@subject_leave)
      end

      context 'failed update' do
        before do
          SubjectLeave.any_instance.expects(:update_attributes).returns(false)
          put :update
        end

        it 'assigns @absentee' do
          assigns(:absentee).should == @subject_leave
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Student.stub(:find).and_return(@student)
    end

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        @attendance = FactoryGirl.build(:attendance)
        Attendance.stub(:find).and_return(@attendance)
        @attendance.should_receive(:delete)
        delete :destroy
      end

      it 'assigns @config' do
        assigns(:config).should == @configuration
      end

      it 'assigns @absentee' do
        assigns(:absentee).should == @attendance
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'renders the update template' do
        response.should render_template('update')
      end
    end

    context '@config.config_value != Daily' do
      before do
        @configuration.config_value = nil
        @subject_leave = FactoryGirl.build(:subject_leave)
        SubjectLeave.stub(:find).and_return(@subject_leave)
        @timetable_entry = FactoryGirl.build(:timetable_entry)
        TimetableEntry.stub(:find_by_subject_id_and_class_timing_id).and_return(@timetable_entry)
        Subject.stub(:find).and_return(@subject)
        @subject_leave.should_receive(:delete)
        delete :destroy
      end

      it 'assigns @absentee' do
        assigns(:absentee).should == @subject_leave
      end

      it 'assigns @tte_entry' do
        assigns(:tte_entry).should == @timetable_entry
      end
    end
  end

=begin
  describe 'GET #only_privileged_employee_allowed' do
    before do
      #controller.unstub!(:only_privileged_employee_allowed)
      controller.stub(:current_user).and_return(@user)
    end

    context '@current_user.employee? is true' do
      before do
        @user.stub(:employee?).and_return(true)
        @employee = FactoryGirl.build(:employee)
        @user.stub(:employee_record).and_return(@employee)

      end

      context '@employee_subjects is empty AND @privilege not include "StudentAttendanceRegister"' do
        before do
          @user.employee_record.stub(:subjects).and_return([])
          @user.stub(:privileges).and_return([])
          controller.instance_eval(only_privileged_employee_allowed)
        end

        it 'assigns @privilege' do
          assigns(:privilege).should == []
        end

        it 'assigns @employee_subjects' do
          assigns(:employee_subjects).should == []
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('flash_msg4')}"
        end

        it 'redirects to action dashboard' do
          response.should redirect_to(:controller => 'user', :action => 'dashboard')
        end
      end

      context '@employee_subjects is any OR @privilege include "StudentAttendanceRegister"' do
        context '@employee_subjects is any' do
          before do
            @user.employee_record.stub(:subjects).and_return([subject])
            @user.stub(:privileges).and_return([])
            controller.instance_eval(only_privileged_employee_allowed)
          end

          it 'assigns @allow_access' do
            assigns(:allow_access).should be_true
          end
        end

        context '@privilege include "StudentAttendanceRegister"' do
          before do
            @user.employee_record.stub(:subjects).and_return([])
            @privilege = FactoryGirl.build(:privilege, :name => 'StudentAttendanceRegister')
            @user.stub(:privileges).and_return([@privilege])
            controller.instance_eval(only_privileged_employee_allowed)
          end

          it 'assigns @allow_access' do
            assigns(:allow_access).should be_true
          end
        end
      end
    end
  end
=end
end