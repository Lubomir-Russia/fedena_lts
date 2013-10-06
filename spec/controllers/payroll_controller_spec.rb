require 'spec_helper'

describe PayrollController do
  before do
    @payroll_category1 = FactoryGirl.create(:payroll_category)
    @payroll_category2 = FactoryGirl.build(:payroll_category)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'POST #add_category' do
    before do
      PayrollCategory.stub(:find_all_by_is_deduction).with(false, :order => "name ASC").and_return([@payroll_category1])
      PayrollCategory.stub(:find_all_by_is_deduction).with(true, :order => "name ASC").and_return([@payroll_category2])
      PayrollCategory.stub(:new).with({ 'these' => 'params' }).and_return(@payroll_category1)
    end

    context 'successful add_category' do
      before do
        PayrollCategory.any_instance.expects(:save).returns(true)
        post :add_category, :category => { 'these' => 'params' }
      end

      it 'assigns @categories' do
        assigns(:categories).should == [@payroll_category1]
      end

      it 'assigns @deductionable_categories' do
        assigns(:deductionable_categories).should == [@payroll_category2]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash1')}"
      end

      it 'redirects to action add_category' do
        response.should redirect_to(:action => 'add_category')
      end
    end
  end

  describe 'POST #edit_category' do
    before do
      PayrollCategory.stub(:all).with(:order => "name ASC").and_return([@payroll_category1])
      PayrollCategory.stub(:find).and_return(@payroll_category1)
    end

    context 'successful edit_category' do
      before do
        PayrollCategory.any_instance.expects(:update_attributes).returns(true)
        post :edit_category
      end

      it 'assigns @categories' do
        assigns(:categories).should == [@payroll_category1]
      end

      it 'assigns @category' do
        assigns(:category).should == @payroll_category1
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash2')}"
      end

      it 'redirects to action add_category' do
        response.should redirect_to(:action => 'add_category')
      end
    end
  end

  describe 'POST #activate_category' do
    before do
      PayrollCategory.stub(:find_all_by_is_deduction).with(false, :order => "name ASC").and_return([@payroll_category1])
      PayrollCategory.stub(:find_all_by_is_deduction).with(true, :order => "name ASC").and_return([@payroll_category2])
      post :activate_category, :id => @payroll_category1.id
    end

    it 'updates @payroll_category1 status to true' do
      PayrollCategory.find(@payroll_category1).status.should be_true
    end

    it 'assigns @categories' do
      assigns(:categories).should == [@payroll_category1]
    end

    it 'assigns @deductionable_categories' do
      assigns(:deductionable_categories).should == [@payroll_category2]
    end

    it 'renders the category partial template' do
      response.should render_template(:partial => 'category')
    end
  end

  describe 'POST #inactivate_category' do
    before do
      PayrollCategory.stub(:find_all_by_is_deduction).with(false, :order => "name ASC").and_return([@payroll_category1])
      PayrollCategory.stub(:find_all_by_is_deduction).with(true, :order => "name ASC").and_return([@payroll_category2])
      post :inactivate_category, :id => @payroll_category1.id
    end

    it 'updates @payroll_category1 status to false' do
      PayrollCategory.find(@payroll_category1).status.should be_false
    end

    it 'assigns @categories' do
      assigns(:categories).should == [@payroll_category1]
    end

    it 'assigns @deductionable_categories' do
      assigns(:deductionable_categories).should == [@payroll_category2]
    end

    it 'renders the category partial template' do
      response.should render_template(:partial => 'category')
    end
  end

  describe 'DELETE #delete_category' do
    context 'params[:id] is present' do
      context 'employees is empty' do
        before do
          EmployeeSalaryStructure.stub(:find_all_by_payroll_category_id).and_return([])
          PayrollCategory.stub(:find).and_return(@payroll_category1)
          PayrollCategory.stub(:all).and_return([@payroll_category1])
        end

        it 'calls @payroll_category1.destroy' do
          @payroll_category1.should_receive(:destroy)
          delete :delete_category, :id => 1
        end

        context 'delete_category with param id' do
          before { delete :delete_category, :id => 1 }

          it 'assigns @departments' do
            assigns(:departments).should == [@payroll_category1]
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('flash3')}"
          end

          it 'redirects to action add_category' do
            response.should redirect_to(:action => 'add_category')
          end
        end
      end

      context 'employees is any' do
        before do
          @employee_salary_structure = FactoryGirl.build(:employee_salary_structure)
          EmployeeSalaryStructure.stub(:find_all_by_payroll_category_id).and_return([@employee_salary_structure])
          delete :delete_category, :id => 1
        end

        it 'assigns flash[:warn_notice]' do
          flash[:warn_notice].should == "#{@controller.t('flash4')}"
        end

        it 'redirects to action add_category' do
          response.should redirect_to(:action => 'add_category')
        end
      end
    end

    context 'params[:id] is present' do
      before { delete :delete_category }

      it 'redirects to action add_category' do
        response.should redirect_to(:action => 'add_category')
      end
    end
  end

  describe 'POST #manage_payroll' do
    before { @employee = FactoryGirl.create(:employee) }

    context '@independent_categories || @dependent_categories is any' do
      before do
        PayrollCategory.stub(:find_all_by_payroll_category_id_and_status).with(nil, true).and_return([@payroll_category1])
        PayrollCategory.stub(:find_all_by_status).with(true, :conditions => "payroll_category_id <> ''").and_return([@payroll_category2])
      end

      context 'payroll_created is empty' do
        before do
          EmployeeSalaryStructure.stub(:find_all_by_employee_id).and_return([])
          post :manage_payroll, :id => @employee.id, :manage_payroll => { 1 => {:amount => 15}, 2 => {:amount => 25} }
        end

        it 'creates EmployeeSalaryStructure with each manage_payroll param' do
          EmployeeSalaryStructure.find_by_employee_id_and_payroll_category_id_and_amount(@employee.id, 1, 15).should be_present
          EmployeeSalaryStructure.find_by_employee_id_and_payroll_category_id_and_amount(@employee.id, 2, 25).should be_present
          EmployeeSalaryStructure.all.count.should == 2
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('data_saved_for')} #{@employee.first_name}.  #{@controller.t('new_admission_link')} <a href='/employee/admission1'>Click Here</a>"
        end

        it 'redirects to employee profile' do
          response.should redirect_to(:controller => "employee", :action => "profile", :id => @employee.id)
        end
      end

      context 'payroll_created is any' do
        before do
          @employee_salary_structure = FactoryGirl.build(:employee_salary_structure)
          EmployeeSalaryStructure.stub(:find_all_by_employee_id).and_return([@employee_salary_structure])
          post :manage_payroll, :id => @employee.id
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('data_saved_for')} #{@employee.first_name}.  #{@controller.t('new_admission_link')} <a href='/employee/admission1'>Click Here</a>"
        end

        it 'redirects to employee profile' do
          response.should redirect_to(:controller => "employee", :action => "profile", :id => @employee.id)
        end
      end
    end

    context '@independent_categories && @dependent_categories are empty' do
      before do
        PayrollCategory.stub(:find_all_by_payroll_category_id_and_status).with(nil, true).and_return([])
        PayrollCategory.stub(:find_all_by_status).with(true, :conditions => "payroll_category_id <> ''").and_return([])
        post :manage_payroll, :id => @employee.id
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('data_saved_for')} #{@employee.first_name}.  #{@controller.t('new_admission_link')} <a href='/employee/admission1'>Click Here</a>"
      end

      it 'redirects to employee profile' do
        response.should redirect_to(:controller => "employee", :action => "profile", :id => @employee.id)
      end
    end
  end

  describe 'GET #update_dependent_fields' do
    before do
      @payroll_category1.percentage = 25
      PayrollCategory.stub(:find_all_by_payroll_category_id_and_status).and_return([@payroll_category1])
      post :update_dependent_fields, :cat_id => 5, :amount => 10
    end

    it 'assigns @dependent_categories' do
      assigns(:dependent_categories).should == [@payroll_category1]
    end

    it 'response rjs' do
      response.should include_text("$(\"manage_payroll_#{@payroll_category1.id}_amount\").value = 2.5;")
      response.should include_text("new Ajax.Request('/payroll/update_dependent_fields', {asynchronous:true, evalScripts:true, parameters:'amount='+ 2.5 + '&cat_id=' + #{@payroll_category1.id}})")
    end
  end

  describe 'POST #edit_payroll_details' do
    before do
      @employee = FactoryGirl.create(:employee)
      Employee.stub(:find).and_return(@employee)
      PayrollCategory.stub(:find_all_by_payroll_category_id_and_status).with(nil, true).and_return([@payroll_category1])
      PayrollCategory.stub(:find_all_by_status).and_return([@payroll_category2])
    end

    context 'found row_id' do
      before do
        @employee_salary_structure = FactoryGirl.create(:employee_salary_structure)
        EmployeeSalaryStructure.stub(:find_by_employee_id_and_payroll_category_id).and_return(@employee_salary_structure)
        post :edit_payroll_details, :id => @employee.id, :manage_payroll => { 1 => {:amount => 15} }
      end

      it 'updates EmployeeSalaryStructure with each manage_payroll param' do
        EmployeeSalaryStructure.find_by_employee_id_and_payroll_category_id_and_amount(@employee.id, 1, 15).should == @employee_salary_structure
      end
    end

    context 'row_id is present' do
      before do
        EmployeeSalaryStructure.stub(:find_by_employee_id_and_payroll_category_id).and_return(nil)
        post :edit_payroll_details, :id => @employee.id, :manage_payroll => { 1 => {:amount => 15}, 2 => {:amount => 25} }
      end

      it 'creates EmployeeSalaryStructure with each manage_payroll param' do
        EmployeeSalaryStructure.find_by_employee_id_and_payroll_category_id_and_amount(@employee.id, 1, 15).should be_present
        EmployeeSalaryStructure.find_by_employee_id_and_payroll_category_id_and_amount(@employee.id, 2, 25).should be_present
        EmployeeSalaryStructure.all.count.should == 2
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('data_saved_for')} #{@employee.first_name}"
      end

      it 'redirects to employee profile' do
        response.should redirect_to(:controller => "employee", :action => "profile", :id => @employee.id)
      end
    end
  end
end