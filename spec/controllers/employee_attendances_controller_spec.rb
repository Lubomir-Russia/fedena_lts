require 'spec_helper'

describe EmployeeAttendancesController do
  before do
    Configuration.stub(:find_by_config_value).with("HR").and_return(true)
    @employee = FactoryGirl.build(:employee)
    @employee_leave = FactoryGirl.build(:employee_leave)
    @employee_leave_type = FactoryGirl.build(:employee_leave_type)
    @employee_attendance = FactoryGirl.build(:employee_attendance)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      @employee_department = FactoryGirl.build(:general_department)
      EmployeeDepartment.stub(:find_all_by_status).and_return([@employee_department])
      get :index
    end

    it 'assigns @departments' do
      assigns(:departments).should == [@employee_department]
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'GET #show' do
    before do
      @employee_department = FactoryGirl.build(:general_department)
      EmployeeDepartment.stub(:find).and_return(@employee_department)
      Employee.stub(:find_all_by_employee_department_id).and_return([@employee])
    end

    context 'params[:next] is present' do
      before do
        get :show, :next => Date.new(2013, 7, 15)
      end

      it 'assigns @dept' do
        assigns(:dept).should == @employee_department
      end

      it 'assigns @employees' do
        assigns(:employees).should == [@employee]
      end

      it 'assigns @today' do
        assigns(:today).should == Date.new(2013, 7, 15)
      end

      it 'assigns @start_date' do
        assigns(:start_date).should == Date.new(2013, 7, 1)
      end

      it 'assigns @end_date' do
        assigns(:end_date).should == Date.new(2013, 7, 31)
      end

      it 'renders the show template' do
        response.should render_template('show')
      end
    end

    context 'params[:next] is nil' do
      before { get :show }

      it 'assigns @today' do
        assigns(:today).should == Date.current
      end
    end
  end

  describe 'GET #new' do
    before do
      Employee.stub(:find).and_return(@employee)
      EmployeeLeaveType.stub(:find_all_by_status).and_return([@employee_leave_type])
      get :new, :id => 1
    end

    it 'assigns new reccord as @attendance' do
      assigns(:attendance).should be_new_record
    end

    it 'assigns @employee' do
      assigns(:employee).should == @employee
    end

    it 'assigns @date with param id' do
      assigns(:date).should == '1'
    end

    it 'assigns @leave_types' do
      assigns(:leave_types).should == [@employee_leave_type]
    end

    it 'renders the new template' do
      response.should render_template('new')
    end
  end

  describe 'POST #create' do
    before do
      EmployeeAttendance.stub(:new).and_return(@employee_attendance)
      Employee.stub(:find).and_return(@employee)
      @employee_leave.leave_taken = 1
      EmployeeLeave.stub(:find_by_employee_id_and_employee_leave_type_id).and_return(@employee_leave)
    end

    context 'successful create' do
      before { EmployeeAttendance.any_instance.expects(:save).returns(true) }

      context '@attendance.is_half_day is true' do
        before do
          @employee_attendance.stub(:is_half_day).and_return(true)
          post :create, :employee_attendance => { :employee_id => 1, :attendance_date => Date.current }
        end

        it 'assigns @attendance' do
          assigns(:attendance).should == @employee_attendance
        end

        it 'assigns @employee' do
          assigns(:employee).should == @employee
        end

        it 'assigns @date' do
          assigns(:date).should == Date.current
        end

        it 'assigns @reset_count' do
          assigns(:reset_count).should == @employee_leave
        end

        it 'updates @reset_count.leave_taken + 0.5' do
          assigns(:reset_count).leave_taken.should == 1.5
        end

        it 'renders the create template' do
          response.should render_template('create')
        end
      end

      context '@attendance.is_half_day is true' do
        before do
          @employee_attendance.stub(:is_half_day).and_return(false)
          post :create, :employee_attendance => {}
        end

        it 'updates @reset_count.leave_taken + 1' do
          assigns(:reset_count).leave_taken.should == 2
        end
      end
    end

    context 'failed create' do
      before do
        EmployeeAttendance.any_instance.expects(:save).returns(false)
        post :create, :employee_attendance => {}
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #edit' do
    before do
      EmployeeAttendance.stub(:find).and_return(@employee_attendance)
      Employee.stub(:find).and_return(@employee)
      EmployeeLeaveType.stub(:find_all_by_status).and_return([@employee_leave_type])
      get :edit
    end

    it 'assigns @attendance' do
      assigns(:attendance).should == @employee_attendance
    end

    it 'assigns @employee' do
      assigns(:employee).should == @employee
    end

    it 'assigns @leave_types' do
      assigns(:leave_types).should == [@employee_leave_type]
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end
  end

  describe 'PUT #update' do
    let(:employee_leave1) { FactoryGirl.build(:employee_leave, :leave_taken => 1) }
    let(:employee_leave2) { FactoryGirl.build(:employee_leave, :leave_taken => 1) }

    before do
      EmployeeAttendance.stub(:find).and_return(@employee_attendance)
      @employee_attendance.attendance_date = Date.current - 3.months
      EmployeeLeave.stub(:find_by_employee_id_and_employee_leave_type_id).and_return(employee_leave1, employee_leave2)
      EmployeeLeaveType.stub(:find_by_id).and_return(@employee_leave_type)
      Employee.stub(:find).and_return(@employee)
    end

    context 'successful update' do
      before { EmployeeAttendance.any_instance.expects(:valid?).returns(true) }

      context '@attendance.employee_leave_type_id == leave_type.id' do
        before { @employee_attendance.employee_leave_type = @employee_leave_type }

        context 'changed is_half_day, @attendance.is_half_day != param is_half_day' do
          context '@attendance.is_half_day is true' do
            before do
              @employee_attendance.is_half_day = true
              put :update, :employee_attendance => { :is_half_day => false }
            end

            it 'updates @reset_count.leave_taken + 0.5' do
              assigns(:reset_count).leave_taken.should == 1.5
            end

            it 'assigns @employee' do
              assigns(:employee).should == @employee
            end

            it 'assigns @date' do
              assigns(:date).should == Date.current - 3.months
            end

            it 'renders the update template' do
              response.should render_template('update')
            end
          end

          context '@attendance.is_half_day is false' do
            before do
              @employee_attendance.is_half_day = false
              put :update, :employee_attendance => { :is_half_day => true }
            end

            it 'updates @reset_count.leave_taken - 0.5' do
              assigns(:reset_count).leave_taken.should == 0.5
            end
          end
        end
      end

      context '@attendance.employee_leave_type_id != leave_type.id' do
        before do
          @employee_attendance.employee_leave_type_id = nil
        end

        context '@attendance.is_half_day and param is_half_day are true' do
          before do
            @employee_attendance.is_half_day = true
            put :update, :employee_attendance => { :is_half_day => true }
          end

          it 'updates @reset_count.leave_taken - 0.5' do
            assigns(:reset_count).leave_taken.should == 0.5
          end

          it 'updates @new_reset_count.leave_taken + 0.5' do
            assigns(:new_reset_count).leave_taken.should == 1.5
          end

          it 'assigns @new_reset_count' do
            assigns(:new_reset_count).should == employee_leave2
          end
        end

        context '@attendance.is_half_day and param is_half_day are false' do
          before do
            @employee_attendance.is_half_day = false
            put :update, :employee_attendance => { :is_half_day => false }
          end

          it 'updates @reset_count.leave_taken - 1.0' do
            assigns(:reset_count).leave_taken.should == 0
          end

          it 'updates @new_reset_count.leave_taken + 1.0' do
            assigns(:new_reset_count).leave_taken.should == 2.0
          end
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      EmployeeAttendance.stub(:find).and_return(@employee_attendance)
      @employee_attendance.attendance_date = Date.current
      EmployeeLeave.stub(:find_by_employee_id_and_employee_leave_type_id).and_return(@employee_leave)
      @employee_leave.leave_taken = 1
      Employee.stub(:find).and_return(@employee)
    end

    it 'calls delete method' do
      @employee_attendance.should_receive(:delete)
      delete :destroy
    end

    context '@attendance.is_half_day is true' do
      before do
        @employee_attendance.stub(:is_half_day).and_return(true)
        delete :destroy
      end

      it 'updates @reset_count.leave_taken - 0.5' do
        assigns(:reset_count).leave_taken.should == 0.5
      end

      it 'assigns @employee' do
        assigns(:employee).should == @employee
      end

      it 'assigns @date' do
        assigns(:date).should == Date.current
      end

      it 'renders the update template' do
        response.should render_template('update')
      end
    end

    context '@attendance.is_half_day is false' do
      before do
        @employee_attendance.stub(:is_half_day).and_return(false)
        delete :destroy
      end

      it 'updates @reset_count.leave_taken - 1.0' do
        assigns(:reset_count).leave_taken.should == 0
      end
    end
  end
end