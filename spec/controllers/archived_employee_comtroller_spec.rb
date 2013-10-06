require 'spec_helper'

describe ArchivedEmployeeController do
  before do
    Configuration.stub(:find_by_config_value).and_return(true)
    @archived_employee = FactoryGirl.build(:archived_employee)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #profile' do
    before do
      @archived_employee.reporting_manager_id = 5
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      @reminder = FactoryGirl.build(:reminder)
      Reminder.stub(:find_all_by_recipient_and_is_read).and_return(@reminder)
    end

    context 'GET #profile' do
      before do
        @archived_employee.experience_year = 3
        @archived_employee.experience_month = 7
        @archived_employee.joining_date = Date.current - 1.years
        get :profile, :id => 1
      end

      it 'assigns @current_user' do
        assigns(:current_user).should == @user
      end

      it 'assigns @employee' do
        assigns(:employee).should == @archived_employee
      end

      it 'assigns @new_reminder_count' do
        assigns(:new_reminder_count).should == @reminder
      end

      it 'assigns @total_years' do
        assigns(:total_years).should == 4
      end

      it 'assigns @total_months' do
        assigns(:total_months).should == 7
      end

      it 'renders the profile template' do
        response.should render_template('profile')
      end
    end

    context '@archived_employee.gender = f' do
      before do
        @archived_employee.gender = 'f'
        get :profile, :id => 1
      end

      it 'assigns @gender to Female' do
        assigns(:gender).should == 'Female'
      end
    end

    context '@archived_employee.gender != f' do
      before do
        @archived_employee.gender = nil
        get :profile, :id => 1
      end

      it 'assigns @gender to Male' do
        assigns(:gender).should == 'Male'
      end
    end

    context '@archived_employee.status is true' do
      before do
        @archived_employee.status = true
        get :profile, :id => 1
      end

      it 'assigns @status to Active' do
        assigns(:status).should == 'Active'
      end
    end

    context '@archived_employee.status is false' do
      before do
        @archived_employee.status = false
        get :profile, :id => 1
      end

      it 'assigns @status to Inactive' do
        assigns(:status).should == 'Inactive'
      end
    end

    context 'found Employee with reporting_manager_id' do
      before do
        @employee = FactoryGirl.build(:employee, :first_name => 'Employee FN')
        Employee.stub(:find_by_id).with(@archived_employee.reporting_manager_id).and_return(@employee)
        get :profile, :id => 1
      end

      it 'assigns @reporting_manager to Employee FN' do
        assigns(:reporting_manager).should == 'Employee FN'
      end
    end

    context 'not found Employee with reporting_manager_id' do
      before { Employee.stub(:find_by_id).and_return(nil) }

      context 'found ArchivedEmployee  with reporting_manager_id' do
        before do
          @archived_employee1 = FactoryGirl.build(:archived_employee, :first_name => 'Archived Employee FN')
          ArchivedEmployee.stub(:find_by_id).with(@archived_employee.reporting_manager_id).and_return(@archived_employee1)
          get :profile, :id => 1
        end

        it 'assigns @reporting_manager to Archived Employee FN' do
          assigns(:reporting_manager).should == 'Archived Employee FN'
        end
      end
    end
  end

  describe 'GET #profile_general' do
    before { ArchivedEmployee.stub(:find).and_return(@archived_employee) }

    context '@archived_employee.gender = f' do
      before do
        @archived_employee.gender = 'f'
        get :profile_general, :id => 1
      end

      it 'assigns @gender to Female' do
        assigns(:gender).should == 'Female'
      end
    end

    context '@archived_employee.gender != f' do
      before do
        @archived_employee.gender = nil
        get :profile_general, :id => 1
      end

      it 'assigns @gender to Male' do
        assigns(:gender).should == 'Male'
      end
    end

    context '@archived_employee.status is true' do
      before do
        @archived_employee.status = true
        get :profile_general, :id => 1
      end

      it 'assigns @status to Active' do
        assigns(:status).should == 'Active'
      end
    end

    context '@archived_employee.status is false' do
      before do
        @archived_employee.status = false
        get :profile_general, :id => 1
      end

      it 'assigns @status to Inactive' do
        assigns(:status).should == 'Inactive'
      end
    end

    context 'GET #profile_general' do
      before do
        @archived_employee.first_name = 'Reporting Manager Name'
        @archived_employee.reporting_manager_id = 5
        @archived_employee.experience_year = 3
        @archived_employee.experience_month = 15
        @archived_employee.joining_date = Date.current - 3.years - 4.months
        get :profile_general, :id => 1
      end

      it 'assigns @employee' do
        assigns(:employee).should == @archived_employee
      end

      it 'assigns @reporting_manager' do
        assigns(:reporting_manager).should == 'Reporting Manager Name'
      end

      it 'assigns @total_years' do
        assigns(:total_years).should == 6
      end

      it 'assigns @total_months' do
        assigns(:total_months).should == 19
      end

      it 'renders the general partial template' do
        response.should render_template(:partial => 'general')
      end
    end
  end

  describe 'GET #profile_personal' do
    before do
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      get :profile_personal, :id => 1
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'renders the personal partial template' do
      response.should render_template(:partial => 'personal')
    end
  end

  describe 'GET #profile_address' do
    before do
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      @archived_employee.home_country_id = 1
      @archived_employee.office_country_id = 2
      @country1 = FactoryGirl.build(:country, :name => 'Country 1')
      @country2 = FactoryGirl.build(:country, :name => 'Country 2')
      Country.stub(:find).and_return(@country1, @country2)
      get :profile_address, :id => 3
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'assigns @home_country' do
      assigns(:home_country).should == 'Country 1'
    end

    it 'assigns @office_country' do
      assigns(:office_country).should == 'Country 2'
    end

    it 'renders the address partial template' do
      response.should render_template(:partial => 'address')
    end
  end

  describe 'GET #profile_contact' do
    before do
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      get :profile_contact, :id => 1
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'renders the contact partial template' do
      response.should render_template(:partial => 'contact')
    end
  end

  describe 'GET #profile_bank_details' do
    before do
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      @archived_employee_bank_detail = FactoryGirl.build(:archived_employee_bank_detail)
      ArchivedEmployeeBankDetail.stub(:find_all_by_employee_id).and_return([@archived_employee_bank_detail])
      get :profile_bank_details
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'assigns @bank_details' do
      assigns(:bank_details).should == [@archived_employee_bank_detail]
    end

    it 'renders the bank_details partial template' do
      response.should render_template(:partial => 'bank_details')
    end
  end

  describe 'GET #profile_additional_details' do
    before do
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      @archived_employee_additional_detail = FactoryGirl.build(:archived_employee_additional_detail)
      ArchivedEmployeeAdditionalDetail.stub(:find_all_by_employee_id).and_return([@archived_employee_additional_detail])
      get :profile_additional_details
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'assigns @additional_details' do
      assigns(:additional_details).should == [@archived_employee_additional_detail]
    end

    it 'renders the additional_details partial template' do
      response.should render_template(:partial => 'additional_details')
    end
  end

  describe 'GET #profile_payroll_details' do
    before do
      @configuration = FactoryGirl.create(:configuration, :config_key => 'CurrencyType', :config_value => 'Config Value')
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      @archived_employee_salary_structure = FactoryGirl.build(:archived_employee_salary_structure)
      ArchivedEmployeeSalaryStructure.stub(:find_all_by_employee_id).and_return([@archived_employee_salary_structure])
      get :profile_payroll_details, :id => 1
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'assigns @currency_type' do
      assigns(:currency_type).should == 'Config Value'
    end

    it 'assigns @payroll_details' do
      assigns(:payroll_details).should == [@archived_employee_salary_structure]
    end

    it 'renders the payroll_details partial template' do
      response.should render_template(:partial => 'payroll_details')
    end
  end

  describe 'GET #profile_pdf' do
    before { ArchivedEmployee.stub(:find).and_return(@archived_employee) }

    context '@archived_employee.gender == f' do
      before do
        @archived_employee.gender = 'f'
        controller.stub!(:render)
        get :profile_pdf, :id => 1
      end

      it 'assigns @gender' do
        assigns(:gender).should == 'Female'
      end
    end

    context '@archived_employee.gender != f' do
      before do
        @archived_employee.gender = nil
        controller.stub!(:render)
        get :profile_pdf, :id => 1
      end

      it 'assigns @gender' do
        assigns(:gender).should == 'Male'
      end
    end

    context '@archived_employee.status is true' do
      before do
        @archived_employee.status = true
        controller.stub!(:render)
        get :profile_pdf, :id => 1
      end

      it 'assigns @status' do
        assigns(:status).should == 'Active'
      end
    end

    context '@archived_employee.status is false' do
      before do
        @archived_employee.status = false
        controller.stub!(:render)
        get :profile_pdf, :id => 1
      end

      it 'assigns @status' do
        assigns(:status).should == 'Inactive'
      end
    end

    context 'GET #profile_pdf' do
      before do
        @archived_employee.first_name = 'Reporting Manager Name'
        @archived_employee.reporting_manager_id = 5
        @archived_employee.experience_year = 3
        @archived_employee.experience_month = 16
        @archived_employee.joining_date = Date.current - 2.years - 8.months
        @archived_employee.home_country_id = 6
        @archived_employee.office_country_id = 7
        @country1 = FactoryGirl.build(:country, :name => 'Country 1')
        @country2 = FactoryGirl.build(:country, :name => 'Country 2')
        Country.stub(:find).and_return(@country1, @country2)
        @archived_employee_bank_detail = FactoryGirl.build(:archived_employee_bank_detail)
        ArchivedEmployeeBankDetail.stub(:find_all_by_employee_id).and_return([@archived_employee_bank_detail])
        @archived_employee_additional_detail = FactoryGirl.build(:archived_employee_additional_detail)
        ArchivedEmployeeAdditionalDetail.stub(:find_all_by_employee_id).and_return([@archived_employee_additional_detail])
        get :profile_pdf, :id => 1
      end

      it 'assigns @employee' do
        assigns(:employee).should == @archived_employee
      end

      it 'assigns @reporting_manager' do
        assigns(:reporting_manager).should == 'Reporting Manager Name'
      end

      it 'assigns @total_years' do
        assigns(:total_years).should == 5
      end

      it 'assigns @total_months' do
        assigns(:total_months).should == 24
      end

      it 'assigns @home_country' do
        assigns(:home_country).should == 'Country 1'
      end

      it 'assigns @office_country' do
        assigns(:office_country).should == 'Country 2'
      end

      it 'assigns @bank_details' do
        assigns(:bank_details).should == [@archived_employee_bank_detail]
      end

      it 'assigns @additional_details' do
        assigns(:additional_details).should == [@archived_employee_additional_detail]
      end

      it 'renders the pdf' do
        response.should render_template(:pdf => 'profile_pdf')
      end
    end
  end

  describe 'GET #show' do
    before do
      @archived_employee.stub(:photo_filename).and_return('filename')
      ArchivedEmployee.stub(:find).and_return(@archived_employee)
      controller.should_receive(:send_data)
      get :show, :id => 1
    end

    it 'assigns @employee' do
      assigns(:employee).should == @archived_employee
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end
end