require 'spec_helper'

describe AttendanceReportsController do
  before do
    controller.stub!(:only_assigned_employee_allowed)
    controller.stub!(:default_time_zone_present_time)
    controller.instance_variable_set(:@local_tzone_time, Time.current)

    @configuration = FactoryGirl.build(:configuration)
    @batch = FactoryGirl.build(:batch)
    @subject = FactoryGirl.build(:general_subject)
    @student = FactoryGirl.create(:student)
    @subject_leave = FactoryGirl.build(:subject_leave, :student => @student)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
    controller.stub(:current_user).and_return(@user)
  end

  describe 'GET #index' do
    before do
      Configuration.stub(:find_by_config_key).and_return(@configuration)
    end

    context 'current_user is admin' do
      before do
        @user.stub(:admin?).and_return(true)
        Batch.stub(:active).and_return([@batch])
        get :index
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch]
      end

      it 'assigns @config' do
        assigns(:config).should == @configuration
      end

      it 'renders the index template' do
        response.should render_template('index')
      end
    end

    context '@user privileges include StudentAttendanceView' do
      before do
        @user.stub(:admin?).and_return(false)
        @privilege = FactoryGirl.build(:privilege, :name => 'StudentAttendanceView')
        @user.stub(:privileges).and_return([@privilege])
        Batch.stub(:active).and_return([@batch])
        get :index
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch]
      end
    end

    context '@current_user is employee' do
      before do
        @user.stub(:admin?).and_return(false)
        @user.stub(:privileges).and_return([])
        @user.stub(:employee?).and_return(true)

        Batch.stub(:find_all_by_employee_id).and_return([@batch])
        @batch1 = FactoryGirl.build(:batch)
        @subject = FactoryGirl.build(:general_subject, :batch => @batch1)
        @employee = FactoryGirl.build(:employee, :subjects => [@subject])
        @user.stub(:employee_record).and_return(@employee)
        get :index
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch, @batch1]
      end
    end
  end

  describe 'GET #subject' do
    before { Batch.stub(:find).and_return(@batch) }

    context '@current_user.employee? && @allow_access? are true' do
      before do
        @user.stub(:employee?).and_return(true)
        controller.instance_variable_set(:@allow_access, true)
      end

      context 'role_symb include (:student_attendance_view)' do
        before do
          @user.stub(:role_symbols).and_return([:student_attendance_view])
          Subject.stub(:all).and_return([@subject])
          get :subject
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject]
        end

        it 'replaces element subject with partial template' do
          response.should have_rjs(:replace_html, 'subject')
          response.should render_template(:partial => 'subject')
        end
      end

      context 'role_symb include (:student_attendance_register)' do
        before do
          @user.stub(:role_symbols).and_return([:student_attendance_register])
          Subject.stub(:all).and_return([@subject])
          get :subject
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject]
        end
      end

      context 'role_symb not include :student_attendance_view, :student_attendance_register' do
        before do
          @user.stub(:role_symbols).and_return([:admin])
        end

        context '@batch.employee_id.to_i == @current_user.employee_record.id' do
          before do
            @employee = FactoryGirl.build(:employee, :id => 5)
            @batch.employee_id = 5
            @user.stub(:employee_record).and_return(@employee)
            @batch.stub(:subjects).and_return([@subject])
            get :subject
          end

          it 'assigns @subjects' do
            assigns(:subjects).should == [@subject]
          end
        end

        context '@batch.employee_id.to_i != @current_user.employee_record.id' do
          before do
            @employee = FactoryGirl.build(:employee, :id => 5)
            @batch.employee_id = 6
            @user.stub(:employee_record).and_return(@employee)
            Subject.stub(:all).and_return([@subject])
            get :subject
          end

          it 'assigns @subjects' do
            assigns(:subjects).should == [@subject]
          end
        end
      end
    end
  end

  describe 'GET #mode' do
    before do
      Batch.stub(:find).and_return(@batch)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
    end

    context '@config.config_value == Daily' do
      before { @configuration.config_value = 'Daily' }

      context 'params[:subject_id] is present' do
        before { get :mode, :subject_id => 1 }

        it 'assigns @subject' do
          assigns(:subject).should == '1'
        end

        it 'replaces element mode with partial template' do
          response.should have_rjs(:replace_html, 'mode')
          response.should render_template(:partial => 'mode')
        end

        it 'replaces element month' do
          response.should have_rjs(:replace_html, 'month')
        end
      end

      context 'params[:subject_id] is nil' do
        before { get :mode }

        it 'assigns @subject' do
          assigns(:subject).should == 0
        end
      end
    end

    context '@config.config_value != Daily' do
      before { @configuration.config_value = nil }

      context 'params[:subject_id] is present' do
        context 'params[:subject_id] == all_sub' do
          before { get :mode, :subject_id => 'all_sub' }

          it 'assigns @subject' do
            assigns(:subject).should == 0
          end
        end

        context 'params[:subject_id] != all_sub' do
          before { get :mode, :subject_id => 1 }

          it 'assigns @subject' do
            assigns(:subject).should == '1'
          end

          it 'replaces element mode with partial template' do
            response.should have_rjs(:replace_html, 'mode')
            response.should render_template(:partial => 'mode')
          end

          it 'replaces element month' do
            response.should have_rjs(:replace_html, 'month')
          end
        end
      end

      context 'params[:subject_id] is present' do
        before { get :mode }

        it 'replaces element mode' do
          response.should have_rjs(:replace_html, 'mode')
        end

        it 'replaces element month' do
          response.should have_rjs(:replace_html, 'month')
        end
      end
    end
  end

  describe 'GET #show' do
    before do
      @batch.started_on = Date.current - 3.days
      Batch.stub(:find).and_return(@batch)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
    end

    context '@config.config_value != Daily' do
      before { @configuration.config_value = nil }

      context '@mode == Overall' do
        before { @batch.stub(:students).and_return([@student]) }

        context 'params[:subject_id] != 0' do
          before do
            Subject.stub(:find).and_return(@subject)
            @subject.elective_group_id = 5
            @subject.stub(:students).and_return([@student])
            @batch.stub(:subject_hours).and_return({Date.current => [1, 2]})
          end

          context '@grouped[s.id] is present' do
            before do
              SubjectLeave.stub(:count).and_return(1, { @student.id => 1 })
              get :show, :mode => 'Overall', :subject_id => 1
            end

            it 'assigns @batch' do
              assigns(:batch).should == @batch
            end

            it 'assigns @start_date' do
              assigns(:start_date).should == Date.current - 3.days
            end

            it 'assigns @end_date' do
              assigns(:end_date).should == Date.current
            end

            it 'assigns @mode' do
              assigns(:mode).should == 'Overall'
            end

            it 'assigns @config' do
              assigns(:config).should == @configuration
            end

            it 'assigns @students' do
              assigns(:students).should == [@student]
            end

            it 'assigns @subject' do
              assigns(:subject).should == @subject
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @report' do
              assigns(:report).should == 1
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => 1 }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end

            it 'replaces element report with partial template' do
              response.should have_rjs(:replace_html, 'report')
              response.should render_template(:partial => 'report')
            end

            it 'replaces element month' do
              response.should have_rjs(:replace_html, 'month')
            end

            it 'replaces element year' do
              response.should have_rjs(:replace_html, 'year')
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              SubjectLeave.stub(:count).and_return(1, {})
              get :show, :mode => 'Overall', :subject_id => 1
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == {}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end

        context 'params[:subject_id] == 0' do
          before { @batch.stub(:subject_hours).and_return({Date.current => [1, 2]}) }

          context '@grouped[s.id] is present' do
            before do
              @batch.subject_leaves.stub(:all).and_return([@subject_leave])
              get :show, :mode => 'Overall', :subject_id => 0
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @report' do
              assigns(:report).should == [@subject_leave]
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              @batch.subject_leaves.stub(:all).and_return([])
              get :show, :mode => 'Overall', :subject_id => 0
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end
      end

      context '@mode != Overall' do
        before do
          controller.stub!(:render)
          @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,3))
          get :show, :subject_id => 1
        end

        it 'assigns @year' do
          assigns(:year).should == Time.current.to_date.year
        end

        it 'assigns @academic_days' do
          assigns(:academic_days).should == 2
        end

        it 'assigns @subject' do
          assigns(:subject).should == '1'
        end
      end
    end

    context '@config.config_value == Daily' do
      before { @configuration.config_value = 'Daily' }

      context '@mode == Overall' do
        before do
          @batch.stub(:academic_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,13))
          @batch.stub(:students).and_return([@student])
          Attendance.stub(:count).and_return({ @student.id => 1 }, { @student.id => 2 }, { @student.id => 3 })
          get :show, :mode => 'Overall'
        end

        it 'assigns @academic_days' do
          assigns(:academic_days).should == 12
        end

        it 'assigns @students' do
          assigns(:students).should == [@student]
        end

        it 'assigns @leaves' do
          assigns(:leaves).should ==  { @student.id => { "total" => 7.5, "percent" => 62.5 } }
        end

        it 'replaces element report with partial template' do
          response.should have_rjs(:replace_html, 'report')
          response.should render_template(:partial => 'report')
        end

        it 'replaces element month' do
          response.should have_rjs(:replace_html, 'month')
        end

        it 'replaces element year' do
          response.should have_rjs(:replace_html, 'year')
        end
      end

      context '@mode != Overall' do
        before do
          controller.stub!(:render)
          get :show, :subject_id => 1
        end

        it 'assigns @year' do
          assigns(:year).should == Date.current.to_date.year
        end

        it 'assigns @subject' do
          assigns(:subject).should == '1'
        end
      end
    end
  end

  describe 'GET #year' do
    before do
      controller.stub!(:render)
      Batch.stub(:find).and_return(@batch)
      xhr :get, :year, :subject_id => '1', :month => '2'
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @subject' do
      assigns(:subject).should == '1'
    end

    it 'assigns @year' do
      assigns(:year).should == Date.current.to_date.year
    end

    it 'assigns @month' do
      assigns(:month).should == '2'
    end
  end

  describe 'GET #report2' do
    before do
      controller.stub!(:render)
      Batch.stub(:find).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,3))
      controller.instance_variable_set(:@local_tzone_time, Date.new(2013,10,20))
    end

    context '@start_date <= @local_tzone_time.to_date' do
      context '@config.config_value == Daily' do
        before do
          @configuration.config_value = 'Daily'
          @attendance = FactoryGirl.build(:attendance)
          @batch.attendances.stub(:all).and_return([@attendance])
        end

        context '@month == @today.month.to_s' do
          before do
            @param_date = { :month => '10', :year => '2013' }
            get :report2, :month => @param_date[:month], :year => @param_date[:year]
          end

          it 'assigns @batch' do
            assigns(:batch).should == @batch
          end

          it 'assigns @month' do
            assigns(:month).should == '10'
          end

          it 'assigns @year' do
            assigns(:year).should == '2013'
          end

          it 'assigns @students' do
            assigns(:students).should == [@student]
          end

          it 'assigns @config' do
            assigns(:config).should == @configuration
          end

          it 'assigns @date' do
            assigns(:date).should == '01-10-2013'
          end

          it 'assigns @start_date' do
            assigns(:start_date).should == Date.new(2013,10,1).to_date
          end

          it 'assigns @today' do
            assigns(:today).should == Date.new(2013,10,20).to_date
          end

          it 'assigns @end_date' do
            assigns(:end_date).should == Date.new(2013,10,20).to_date
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 2
          end

          it 'assigns @report' do
            assigns(:report).should == [@attendance]
          end
        end

        context '@month != @today.month.to_s' do
          before do
            @param_date = { :month => '9', :year => '2013' }
            get :report2, :month => @param_date[:month], :year => @param_date[:year]
          end

          it 'assigns @end_date' do
            assigns(:end_date).should == Date.new(2013,9,30).to_date
          end
        end
      end

      context '@config.config_value != Daily' do
        before do
          @configuration.config_value = nil
          @param_date = { :month => '9', :year => '2013' }
        end

        context 'params[:subject_id] == 0' do
          before do
            @batch.subject_leaves.stub(:all).and_return([@subject_leave])
            get :report2, :month => @param_date[:month], :year => @param_date[:year], :subject_id => '0'
          end

          it 'assigns @report' do
            assigns(:report).should == [@subject_leave]
          end
        end

        context 'params[:subject_id] != 0' do
          before do
            Subject.stub(:find).and_return(@subject)
            SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave])
            get :report2, :month => @param_date[:month], :year => @param_date[:year], :subject_id => '1'
          end

          it 'assigns @subject' do
            assigns(:subject).should == @subject
          end

          it 'assigns @report' do
            assigns(:report).should == [@subject_leave]
          end
        end
      end
    end

    context '@start_date > @local_tzone_time.to_date' do
      before { get :report2, :month => 12, :year => 2013 }

      it 'assigns @report' do
        assigns(:report).should == ''
      end
    end
  end

  describe 'GET #report' do
    before do
      Batch.stub(:find).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      controller.instance_variable_set(:@local_tzone_time, Date.new(2013,10,20))
    end

    context '@start_date < @batch.started_on.beginning_of_month' do
      before do
        @batch.started_on = Date.new(2013,5,1)
        get :report, :month => 4, :year => 2013
      end

      it 'replaces element report with text' do
        response.should have_rjs(:replace_html, 'report')
        response.should include_text(I18n.t('no_reports'))
      end
    end

    context '@start_date > @batch.ended_on' do
      before do
        @batch.ended_on = Date.new(2013,5,1)
        get :report, :month => 6, :year => 2013
      end

      it 'replaces element report with text' do
        response.should have_rjs(:replace_html, 'report')
        response.should include_text(I18n.t('no_reports'))
      end
    end

    context '@start_date >= @today.next_month.beginning_of_month' do
      before { get :report, :month => 12, :year => 2013 }

      it 'replaces element report with text' do
        response.should have_rjs(:replace_html, 'report')
        response.should include_text(I18n.t('no_reports'))
      end
    end

    context '@start_date >= @batch.started_on.beginning_of_month && @start_date <= @batch.ended_on && @start_date < @today.next_month.beginning_of_month' do
      before do
        @batch.started_on = Date.new(2013,4,1)
        @batch.ended_on = Date.new(2013,12,1)
        @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,13))
      end

      context '@start_date <= @local_tzone_time.to_date' do
        context '@config.config_value == Daily' do
          before do
            @configuration.config_value = 'Daily'
            Attendance.stub(:count).and_return({ @student.id => 1 }, { @student.id => 2 }, { @student.id => 3 })
          end

          context '@month == @today.month.to_s' do
            before { get :report, :month => 10, :year => 2013 }

            it 'assigns @batch' do
              assigns(:batch).should == @batch
            end

            it 'assigns @month' do
              assigns(:month).should == '10'
            end

            it 'assigns @year' do
              assigns(:year).should == '2013'
            end

            it 'assigns @students' do
              assigns(:students).should == [@student]
            end

            it 'assigns @config' do
              assigns(:config).should == @configuration
            end

            it 'assigns @date' do
              assigns(:date).should == '01-10-2013'
            end

            it 'assigns @start_date' do
              assigns(:start_date).should == Date.new(2013,10,1).to_date
            end

            it 'assigns @today' do
              assigns(:today).should == Date.new(2013,10,20).to_date
            end

            it 'assigns @end_date' do
              assigns(:end_date).should == Date.new(2013,10,20).to_date
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 12
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => {"total" => 7.5, "percent" => 62.5 } }
            end

            it 'replaces element report with partial template' do
              response.should have_rjs(:replace_html, 'report')
              response.should render_template(:partial => 'report')
            end
          end

          context '@month != @today.month.to_s' do
            before { get :report, :month => 9, :year => 2013 }

            it 'assigns @end_date' do
              assigns(:end_date).should == Date.new(2013,9,30).to_date
            end
          end
        end

        context '@config.config_value != Daily' do
          before { @configuration.config_value = nil }

          context 'params[:subject_id] != 0' do
            before do
              Subject.stub(:find).and_return(@subject)
              @subject.elective_group_id = 5
              @subject.stub(:students).and_return([@student])
              @batch.stub(:subject_hours).and_return({ Date.current => [1,2] })
            end

            context '@grouped[s.id] is present' do
              before do
                SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave])
                get :report, :month => 9, :year => 2013, :student_id => 1
              end

              it 'assigns @subject' do
                assigns(:subject).should == @subject
              end

              it 'assigns @students' do
                assigns(:students).should == [@student]
              end

              it 'assigns @academic_days' do
                assigns(:academic_days).should == 2
              end

              it 'assigns @report' do
                assigns(:report).should == [@subject_leave]
              end

              it 'assigns @grouped' do
                assigns(:grouped).should == { @student.id => [@subject_leave] }
              end

              it 'assigns @leaves' do
                assigns(:leaves).should == { @student.id => {"leave" => 1, "total" => 1, "percent" => 50.0 } }
              end
            end

            context '@grouped[s.id] is nil' do
              before do
                SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave], [])
                get :report, :month => 9, :year => 2013, :student_id => 1
              end

              it 'assigns @leaves' do
                assigns(:leaves).should == { @student.id => {"leave" => 0, "total" => 2, "percent" => 100.0 } }
              end
            end
          end

          context 'params[:subject_id] == 0' do
            before { @batch.stub(:subject_hours).and_return({ Date.current => [1,2] }) }

            context '@grouped[s.id] is present' do
              before do
                @batch.subject_leaves.stub(:all).and_return([@subject_leave])
                get :report, :month => 9, :year => 2013, :subject_id => 0
              end

              it 'assigns @academic_days' do
                assigns(:academic_days).should == 2
              end

              it 'assigns @report' do
                assigns(:report).should == [@subject_leave]
              end

              it 'assigns @grouped' do
                assigns(:grouped).should == { @student.id => [@subject_leave] }
              end

              it 'assigns @leaves' do
                assigns(:leaves).should == { @student.id => {"leave" => 1, "total" => 1, "percent" => 50.0}}
              end
            end
          end
        end
      end
    end
  end

  describe 'GET #student_details' do
    before do
      Student.stub(:find).and_return(@student)
      @student.stub(:batch).and_return(@batch)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
    end

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        @attendance = FactoryGirl.build(:attendance)
        Attendance.stub(:all).and_return([@attendance])
        get :student_details
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @config' do
        assigns(:config).should == @configuration
      end

      it 'assigns @report' do
        assigns(:report).should == [@attendance]
      end

      it 'renders the student_details template' do
        response.should render_template('student_details')
      end
    end

    context '@config.config_value != Daily' do
      before do
        @configuration.config_value = nil
        SubjectLeave.stub(:all).and_return([@subject_leave])
        get :student_details
      end

      it 'assigns @report' do
        assigns(:report).should == [@subject_leave]
      end
    end
  end

  describe 'POST #filter' do
    before do
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Batch.stub(:find).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,3))
      controller.instance_variable_set(:@local_tzone_time, Date.new(2013,10,20))
    end

    context '@start_date <= @local_tzone_time.to_date' do
      context '@config.config_value != Daily' do
        before { @configuration.config_value = nil }

        context 'params[:filter][:subject] != 0' do
          before do
            Subject.stub(:find).and_return(@subject)
            @batch.stub(:subject_hours).and_return({ Date.current => [1,2] })
          end

          context '@grouped[s.id] is present' do
            before do
              SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave])
              post :filter, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,11,15), :range => 'range', :value => 'value', :subject => '1', :report_type => 'mode'}
            end

            it 'assigns @config' do
              assigns(:config).should == @configuration
            end

            it 'assigns @batch' do
              assigns(:batch).should == @batch
            end

            it 'assigns @students' do
              assigns(:students).should == [@student]
            end

            it 'assigns @start_date' do
              assigns(:start_date).should == Date.new(2013,8,10).to_date
            end

            it 'assigns @end_date' do
              assigns(:end_date).should == Date.new(2013,11,15).to_date
            end

            it 'assigns @range' do
              assigns(:range).should == 'range'
            end

            it 'assigns @value' do
              assigns(:value).should == 'value'
            end

            it 'assigns @today' do
              assigns(:today).should == Date.new(2013,10,20).to_date
            end

            it 'assigns @mode' do
              assigns(:mode).should == 'mode'
            end

            it 'assigns @subject' do
              assigns(:subject).should == @subject
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @report' do
              assigns(:report).should == [@subject_leave]
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => {"leave" => 1, "total" => 1, "percent" => 50.0 } }
            end

            it 'renders the filter template' do
              response.should render_template('filter')
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave], [])
              post :filter, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,11,15), :range => 'range', :value => 'value', :subject => '1', :report_type => 'mode'}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => {"leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end

        context 'params[:filter][:subject] == 0' do
          before { @batch.stub(:subject_hours).and_return({ Date.current => [1,2] }) }

          context '@grouped[s.id] is present' do
            before do
              @batch.subject_leaves.stub(:all).and_return([@subject_leave])
              post :filter, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,11,15), :range => 'range', :value => 'value', :subject => '0', :report_type => 'mode'}
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @report' do
              assigns(:report).should == [@subject_leave]
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              @batch.subject_leaves.stub(:all).and_return([@subject_leave], [])
              post :filter, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,11,15), :range => 'range', :value => 'value', :subject => '0', :report_type => 'mode'}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end
      end

      context '@config.config_value == Daily' do
        before do
          @configuration.config_value = 'Daily'
          @batch.stub(:students).and_return([@student])
          Attendance.stub(:count).and_return({ @student.id => 1 }, { @student.id => 2 }, { @student.id => 3 })
        end

        context '@mode == Overall' do
          before do
            @batch.stub(:academic_days).and_return(1..12)
            post :filter, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,11,15), :range => 'range', :value => 'value', :report_type => 'Overall'}
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 12
          end

          it 'assigns @students' do
            assigns(:students).should == [@student]
          end

          it 'assigns @leaves' do
            assigns(:leaves).should == { @student.id => { "total" => 7.5, "percent" => 62.5 } }
          end
        end

        context '@mode != Overall' do
          before do
            @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,13))
            post :filter, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,11,15), :range => 'range', :value => 'value', :report_type => ''}
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 12
          end
        end
      end
    end
  end

  describe 'POST #filter2' do
    before do
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Batch.stub(:find).and_return(@batch)
      @batch.stub(:students).and_return([@student])
    end

    context '@config.config_value != Daily' do
      before { @configuration.config_value = nil }

      context 'params[:filter][:subject] == 0' do
        before do
          @batch.subject_leaves.stub(:all).and_return([@subject_leave])
          post :filter2, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,10,10), :range => 'range', :value => 'value', :subject => '0'}
        end

        it 'assigns @config' do
          assigns(:config).should == @configuration
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @students' do
          assigns(:students).should == [@student]
        end

        it 'assigns @start_date' do
          assigns(:start_date).should == Date.new(2013,8,10).to_date
        end

        it 'assigns @end_date' do
          assigns(:end_date).should == Date.new(2013,10,10).to_date
        end

        it 'assigns @range' do
          assigns(:range).should == 'range'
        end

        it 'assigns @value' do
          assigns(:value).should == 'value'
        end

        it 'assigns @report' do
          assigns(:report).should == [@subject_leave]
        end

        it 'renders the filter2 template' do
          response.should render_template('filter2')
        end
      end

      context 'params[:filter][:subject] != 0' do
        before do
          Subject.stub(:find).and_return(@subject)
          SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave])
          post :filter2, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,10,10), :range => 'range', :value => 'value', :subject => '1'}
        end

        it 'assigns @subject' do
          assigns(:subject).should == @subject
        end

        it 'assigns @report' do
          assigns(:report).should == [@subject_leave]
        end
      end
    end

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        @attendance = FactoryGirl.build(:attendance)
        @batch.attendances.stub(:all).and_return([@attendance])
        post :filter2, :filter => {:start_date => Date.new(2013,8,10), :end_date => Date.new(2013,10,10), :range => 'range', :value => 'value'}
      end

      it 'assigns @report' do
        assigns(:report).should == [@attendance]
      end
    end
  end

  describe 'GET #advance_search' do
    before { get :advance_search }

    it 'assigns @batches' do
      assigns(:batches).should == []
    end

    it 'renders the advance_search template' do
      response.should render_template('advance_search')
    end
  end

  describe 'POST #report_pdf' do
    before do
      controller.stub(:render)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Batch.stub(:find).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      controller.instance_variable_set(:@local_tzone_time, Date.new(2013,10,10))
      @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,3))
    end

    context '@start_date <= @local_tzone_time.to_date' do
      context '@config.config_value != Daily' do
        before { @configuration.config_value = nil }

        context 'params[:filter][:subject] != 0' do
          before do
            Subject.stub(:find).and_return(@subject)
            @batch.stub(:subject_hours).and_return({ Date.current => [1,2] })
          end

          context '@grouped[s.id] is present' do
            before do
              SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave])
              post :report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :range => 'range', :value => 'value', :subject => '1', :report_type => 'mode'}
            end

            it 'assigns @config' do
              assigns(:config).should == @configuration
            end

            it 'assigns @batch' do
              assigns(:batch).should == @batch
            end

            it 'assigns @students' do
              assigns(:students).should == [@student]
            end

            it 'assigns @start_date' do
              assigns(:start_date).should == Date.new(2013,7,10).to_date
            end

            it 'assigns @end_date' do
              assigns(:end_date).should == Date.new(2013,12,10).to_date
            end

            it 'assigns @range' do
              assigns(:range).should == 'range'
            end

            it 'assigns @value' do
              assigns(:value).should == 'value'
            end

            it 'assigns @today' do
              assigns(:today).should == Date.new(2013,10,10).to_date
            end

            it 'assigns @mode' do
              assigns(:mode).should == 'mode'
            end

            it 'assigns @subject' do
              assigns(:subject).should == @subject
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              SubjectLeave.stub(:find_all_by_subject_id).and_return([])
              post :report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :subject => '1'}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end

        context 'params[:filter][:subject] == 0' do
          before { @batch.stub(:subject_hours).and_return({ Date.current => [1,2] }) }

          context '@grouped[s.id] is present' do
            before do
              @batch.subject_leaves.stub(:all).and_return([@subject_leave])
              post :report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :subject => '0'}
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              @batch.subject_leaves.stub(:all).and_return([])
              post :report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :subject => '0'}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end
      end

      context '@config.config_value == Daily' do
        before do
          @configuration.config_value = 'Daily'
          Attendance.stub(:count).and_return({ @student.id => 1 }, { @student.id => 2 }, { @student.id => 3 })
        end

        context '@mode == Overall' do
          before do
            @batch.stub(:academic_days).and_return(1..12)
            post :report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :report_type => 'Overall'}
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 12
          end

          it 'assigns @leaves' do
            assigns(:leaves).should == { @student.id => { "total" => 7.5, "percent" => 62.5 } }
          end
        end

        context '@mode != Overall' do
          before do
            @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,13))
            post :report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10)}
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 12
          end
        end
      end
    end

    context '@start_date <= @local_tzone_time.to_date' do
      before { post :report_pdf, :filter => {:start_date => Date.new(2013,11,10), :end_date => Date.new(2013,12,10)} }

      it 'assigns @report' do
        assigns(:report).should be_blank
      end
    end
  end

  describe 'POST #filter_report_pdf' do
    before do
      controller.stub(:render)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      Batch.stub(:find).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      controller.instance_variable_set(:@local_tzone_time, Date.new(2013,10,10))
      @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,3))
    end

    context '@start_date <= @local_tzone_time.to_date' do
      context '@config.config_value != Daily' do
        before { @configuration.config_value = nil }

        context 'params[:filter][:subject] != 0' do
          before do
            Subject.stub(:find).and_return(@subject)
            @batch.stub(:subject_hours).and_return({ Date.current => [1,2] })
          end

          context '@grouped[s.id] is present' do
            before do
              SubjectLeave.stub(:find_all_by_subject_id).and_return([@subject_leave])
              post :filter_report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :range => 'range', :value => 'value', :subject => '1', :report_type => 'mode'}
            end

            it 'assigns @config' do
              assigns(:config).should == @configuration
            end

            it 'assigns @batch' do
              assigns(:batch).should == @batch
            end

            it 'assigns @students' do
              assigns(:students).should == [@student]
            end

            it 'assigns @start_date' do
              assigns(:start_date).should == Date.new(2013,7,10).to_date
            end

            it 'assigns @end_date' do
              assigns(:end_date).should == Date.new(2013,12,10).to_date
            end

            it 'assigns @range' do
              assigns(:range).should == 'range'
            end

            it 'assigns @value' do
              assigns(:value).should == 'value'
            end

            it 'assigns @mode' do
              assigns(:mode).should == 'mode'
            end

            it 'assigns @subject' do
              assigns(:subject).should == @subject
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              SubjectLeave.stub(:find_all_by_subject_id).and_return([])
              post :filter_report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :subject => '1'}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end

        context 'params[:filter][:subject] == 0' do
          before { @batch.stub(:subject_hours).and_return({ Date.current => [1,2] }) }

          context '@grouped[s.id] is present' do
            before do
              @batch.subject_leaves.stub(:all).and_return([@subject_leave])
              post :filter_report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :subject => '0'}
            end

            it 'assigns @academic_days' do
              assigns(:academic_days).should == 2
            end

            it 'assigns @grouped' do
              assigns(:grouped).should == { @student.id => [@subject_leave] }
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 1, "total" => 1, "percent" => 50.0 } }
            end
          end

          context '@grouped[s.id] is nil' do
            before do
              @batch.subject_leaves.stub(:all).and_return([])
              post :filter_report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :subject => '0'}
            end

            it 'assigns @leaves' do
              assigns(:leaves).should == { @student.id => { "leave" => 0, "total" => 2, "percent" => 100.0 } }
            end
          end
        end
      end

      context '@config.config_value == Daily' do
        before do
          @configuration.config_value = 'Daily'
          Attendance.stub(:count).and_return({ @student.id => 1 }, { @student.id => 2 }, { @student.id => 3 })
        end

        context '@mode == Overall' do
          before do
            @batch.stub(:academic_days).and_return(1..12)
            post :filter_report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10), :report_type => 'Overall'}
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 12
          end

          it 'assigns @leaves' do
            assigns(:leaves).should == { @student.id => { "total" => 7.5, "percent" => 62.5 } }
          end
        end

        context '@mode != Overall' do
          before do
            @batch.stub(:working_days).and_return(Date.new(2013,1,2)..Date.new(2013,1,13))
            post :filter_report_pdf, :filter => {:start_date => Date.new(2013,7,10), :end_date => Date.new(2013,12,10)}
          end

          it 'assigns @academic_days' do
            assigns(:academic_days).should == 12
          end
        end
      end
    end

    context '@start_date <= @local_tzone_time.to_date' do
      before { post :filter_report_pdf, :filter => {:start_date => Date.new(2013,11,10), :end_date => Date.new(2013,12,10)} }

      it 'assigns @report' do
        assigns(:report).should be_blank
      end
    end
  end
end