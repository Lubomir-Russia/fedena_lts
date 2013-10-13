require 'spec_helper'

describe BatchesController do
  before do
    @batch = FactoryGirl.create(:batch)
    @course = FactoryGirl.create(:course, :batches => [@batch])
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      Course.stub(:find_by_id).and_return(@course)
      get :index
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'GET #new' do
    before do
      Course.stub(:find_by_id).and_return(@course)
      get :new
    end

    it 'assigns new record to @batch' do
      assigns(:batch).should be_new_record
    end

    it 'renders the new template' do
      response.should render_template('new')
    end
  end

  describe 'POST #create' do
    before do
      @subject = FactoryGirl.build(:general_subject)
      Course.stub(:find_by_id).and_return(@course)
      Batch.stub(:new).with({ 'these' => 'params' }).and_return(@batch)
    end

    context 'successful create batch' do
      before do
        Batch.any_instance.expects(:save).returns(true)
      end

      context 'params[:import_subjects] is present' do
        context '@previous_batch is present' do
          before do
            Batch.stub(:first).and_return(@batch)
            Subject.stub(:find_all_by_batch_id).and_return([@subject])
          end

          context 'subject.elective_group_id is nil' do
            before do
              @subject.elective_group_id = nil
              post :create, :batch => { 'these' => 'params' }, :import_subjects => true
            end

            it 'assigns flash[:notice]' do
              flash[:notice].should == "#{@controller.t('flash1')}"
            end

            it 'creates Subject' do
              Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
                :max_weekly_classes => @subject.max_weekly_classes, :elective_group_id => @subject.elective_group_id, :credit_hours => @subject.credit_hours, :is_deleted => false}).should be_present
            end

            it 'assigns flash[:subject_import]' do
              flash[:subject_import].should == ["<ol>", "<li>#{@subject.name}</li>", "</ol>"]
            end

            it 'redirects to [@course, @batch]' do
              response.should redirect_to([@course, @batch])
            end
          end

          context 'subject.elective_group_id is present' do
            before do
              @subject.elective_group_id = 5
              @elective_group = FactoryGirl.build(:elective_group)
              ElectiveGroup.stub(:find_by_id).and_return(@elective_group)
            end

            context 'elect_group_exists is nil' do
              before do
                ElectiveGroup.stub(:find_by_name_and_batch_id).and_return(nil)
                post :create, :batch => { 'these' => 'params' }, :import_subjects => true
              end

              it 'creates ElectiveGroup, Subject' do
                elect_group = ElectiveGroup.first(:conditions => {:name => @elective_group.name, :batch_id => @batch.id, :is_deleted => false})
                elect_group.should be_present
                Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
                  :max_weekly_classes => @subject.max_weekly_classes, :elective_group_id => elect_group.id, :credit_hours => @subject.credit_hours, :is_deleted => false}).should be_present
              end
            end

            context 'elect_group_exists is present' do
              before do
                @elective_group.id = 5
                ElectiveGroup.stub(:find_by_name_and_batch_id).and_return(@elective_group)
                post :create, :batch => { 'these' => 'params' }, :import_subjects => true
              end

              it 'creates Subject' do
                Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
                  :max_weekly_classes => @subject.max_weekly_classes, :elective_group_id => 5, :credit_hours => @subject.credit_hours, :is_deleted => false}).should be_present
              end
            end
          end
        end

        context '@previous_batch is nil' do
          before do
            Batch.stub(:first).and_return(nil)
            post :create, :batch => { 'these' => 'params' }, :import_subjects => true
          end

          it 'assigns flash[:no_subject_error]' do
            flash[:no_subject_error].should == "#{@controller.t('flash7')}"
          end
        end
      end

      context 'params[:import_fees] is present' do
        context '@previous_batch is present' do
          before do
            Batch.stub(:first).and_return(@batch)
            @finance_fee_particular = FactoryGirl.build(:finance_fee_particular)
            @finance_fee_category = FactoryGirl.build(:finance_fee_category, :batch => @batch, :fee_particulars => [@finance_fee_particular])
            FinanceFeeCategory.stub(:find_all_by_batch_id).and_return([@finance_fee_category])
          end

          context 'particulars || batch_discounts || category_discounts is any' do
            before do
              @finance_fee_category.fee_particulars.stub(:all).and_return([@finance_fee_particular])
              @finance_fee_particular.should_receive(:deleted_category).and_return(false)

              @batch_fee_discount = FactoryGirl.build(:batch_fee_discount)
              BatchFeeDiscount.stub(:find_all_by_finance_fee_category_id).and_return([@batch_fee_discount])

              @student_category_fee_discount = FactoryGirl.build(:student_category_fee_discount)
              StudentCategoryFeeDiscount.stub(:find_all_by_finance_fee_category_id).and_return([@student_category_fee_discount])
            end

            context 'successful create FinanceFeeCategory' do
              before do
                FinanceFeeCategory.any_instance.expects(:valid?).returns(true)
              end

              context 'successful create FinanceFeeParticular, BatchFeeDiscount, StudentCategoryFeeDiscount' do
                before do
                  FinanceFeeParticular.any_instance.expects(:valid?).returns(true)
                  BatchFeeDiscount.any_instance.expects(:valid?).returns(true)
                  StudentCategoryFeeDiscount.any_instance.expects(:valid?).returns(true)
                  post :create, :batch => { 'these' => 'params' }, :import_fees => true
                  @new_category = FinanceFeeCategory.first
                end

                it 'creates FinanceFeeParticular' do
                  conditions = {:name => @finance_fee_particular.name, :description => @finance_fee_particular.description,
                    :finance_fee_category_id => @new_category.id, :amount => @finance_fee_particular.amount, :student_category_id => @finance_fee_particular.student_category_id,
                    :admission_no => @finance_fee_particular.admission_no, :student_id => @finance_fee_particular.student_id}
                  FinanceFeeParticular.first(:conditions => conditions).should be_present
                end

                it 'creates BatchFeeDiscount' do
                  conditions = {:receiver_id => @batch.id, :finance_fee_category_id => @new_category.id}
                  BatchFeeDiscount.first(:conditions => conditions).should be_present
                end

                it 'creates StudentCategoryFeeDiscount' do
                  conditions = {:finance_fee_category_id => @new_category.id}
                  StudentCategoryFeeDiscount.first(:conditions => conditions).should be_present
                end

                it 'assigns @fee_import_error to false' do
                  assigns(:fee_import_error).should be_false
                end

                it 'assigns flash[:fees_import]' do
                  flash[:fees_import].should == ["<ol>", "<li>#{@finance_fee_category.name}</li>", "</ol>"]
                end
              end

              context 'failed create FinanceFeeParticular, BatchFeeDiscount, StudentCategoryFeeDiscount' do
                before do
                  FinanceFeeParticular.any_instance.expects(:valid?).returns(false)
                  BatchFeeDiscount.any_instance.expects(:valid?).returns(false)
                  StudentCategoryFeeDiscount.any_instance.expects(:valid?).returns(false)
                  post :create, :batch => { 'these' => 'params' }, :import_fees => true
                end

                it 'assigns flash[:warn_notice]' do
                  flash[:warn_notice].should include_text("<span style = 'margin-left: 15px; font-size: 15px, margin-bottom: 20px;'><b>#{@controller.t('following_pblm_occured_while_saving_the_batch')}</b></span>")
                  flash[:warn_notice].should include_text("<li> #{@controller.t('particular')} #{@finance_fee_particular.name} #{@controller.t('import_failed')}.</li>")
                  flash[:warn_notice].should include_text("<li> #{@controller.t('discount')} #{@batch_fee_discount.name} #{@controller.t('import_failed')}.</li>")
                  flash[:warn_notice].should include_text("<li> #{@controller.t('discount')} #{@student_category_fee_discount.name} #{@controller.t('import_failed')}.</li><br/>")
                end
              end
            end

            context 'failed create FinanceFeeCategory' do
              before do
                FinanceFeeCategory.any_instance.expects(:valid?).returns(false)
                post :create, :batch => { 'these' => 'params' }, :import_fees => true
              end

              it 'assigns flash[:warn_notice]' do
                flash[:warn_notice].should include_text("<span style = 'margin-left: 15px; font-size: 15px, margin-bottom: 20px;'><b>#{@controller.t('following_pblm_occured_while_saving_the_batch')}</b></span>")
                flash[:warn_notice].should include_text("<li> #{@controller.t('category')} #{@finance_fee_category.name}1 #{@controller.t('import_failed')}.</li>")
              end
            end
          end

          context 'particulars && batch_discounts && category_discounts are empty' do
            before do
              BatchFeeDiscount.stub(:find_all_by_finance_fee_category_id).and_return([])
              StudentCategoryFeeDiscount.stub(:find_all_by_finance_fee_category_id).and_return([])
              post :create, :batch => { 'these' => 'params' }, :import_fees => true
            end

            it 'assigns flash[:warn_notice]' do
              flash[:warn_notice].should include_text("<span style = 'margin-left: 15px; font-size: 15px, margin-bottom: 20px;'><b>#{@controller.t('following_pblm_occured_while_saving_the_batch')}</b></span>")
              flash[:warn_notice].should include_text("<li> #{@controller.t('category')} #{@finance_fee_category.name}2 #{@controller.t('import_failed')}.</li>")
            end
          end
        end

        context '@previous_batch is nil' do
          before do
            Batch.stub(:first).and_return(nil)
            post :create, :batch => { 'these' => 'params' }, :import_fees => true
          end

          it 'assigns @fee_import_error to true' do
            assigns(:fee_import_error).should be_true
          end
        end
      end
    end

    context 'failed create batch' do
      before do
        Batch.any_instance.expects(:save).returns(false)
        Configuration.stub(:has_gpa?).and_return(true)
        Configuration.stub(:has_cwa?).and_return(true)
        post :create, :batch => { 'these' => 'params' }
      end

      it 'assigns @grade_types' do
        assigns(:grade_types).should == ['GPA', 'CWA']
      end

      it 'renders the new template' do
        response.should render_template('new')
      end
    end
  end

  describe 'GET #show' do
    before do
      @student = FactoryGirl.build(:student)
      @batch.stub(:students).and_return([@student])
      Batch.stub(:find_by_id).and_return(@batch)
      get :show
    end

    it 'assigns @students' do
      assigns(:students).should == [@student]
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end

  describe 'DELETE #destroy' do
    before do
      Batch.stub(:find_by_id).and_return(@batch)
      Course.stub(:find_by_id).and_return(@course)
    end

    context '@batch.students && @batch.subjects are empty' do
      before do
        @batch.stub(:students).and_return([])
        @batch.stub(:subjects).and_return([])
      end

      it 'inactives batch' do
        @batch.should_receive(:inactivate)
        delete :destroy
      end

      it 'assigns flash[:notice]' do
        delete :destroy
        flash[:notice].should == "#{@controller.t('flash4')}"
      end

      it 'redirects to @course' do
        delete :destroy
        response.should redirect_to(@course)
      end
    end

    context '@batch.students is any' do
      before do
        @student = FactoryGirl.build(:student)
        @batch.stub(:students).and_return([@student])
        delete :destroy
      end

      it 'assigns flash[:warn_notice]' do
        flash[:warn_notice].should == "<p>#{@controller.t('batches.flash5')}</p>"
      end

      it 'redirects to [@course, @batch]' do
        response.should redirect_to([@course, @batch])
      end
    end

    context '@batch.subjects is any' do
      before do
        @subject = FactoryGirl.build(:subject)
        @batch.stub(:subjects).and_return([@subject])
        delete :destroy
      end

      it 'assigns flash[:warn_notice]' do
        flash[:warn_notice].should == "<p>#{@controller.t('batches.flash6')}</p>"
      end
    end
  end

  describe 'GET #assign_tutor' do
    before do
      @batch.employee_id = '10'
      Batch.stub(:find_by_id).and_return(@batch)
      @employee_department = FactoryGirl.build(:employee_department)
      EmployeeDepartment.stub(:all).and_return([@employee_department])
      get :assign_tutor
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @assigned_employee' do
      assigns(:assigned_employee).should == ['10']
    end

    it 'assigns @departments' do
      assigns(:departments).should == [@employee_department]
    end

    it 'renders the assign_tutor template' do
      response.should render_template('assign_tutor')
    end
  end

  describe 'GET #update_employees' do
    before do
      Batch.stub(:find_by_id).and_return(@batch)
      @employee = FactoryGirl.build(:employee)
      Employee.stub(:find_all_by_employee_department_id).and_return([@employee])
      get :update_employees
    end

    it 'assigns @employees' do
      assigns(:employees).should == [@employee]
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'replaces element employee-list with partial template' do
      response.should have_rjs(:replace_html, 'employee-list')
      response.should render_template(:partial => 'employee_list')
    end
  end

  describe 'GET #assign_employee' do
    before do
      Batch.stub(:find_by_id).and_return(@batch)
      @employee = FactoryGirl.build(:employee)
      Employee.stub(:find_all_by_employee_department_id).and_return([@employee])
    end

    context '@batch.employee_id is present' do
      before do
        @batch.employee_id = '10'
        get :assign_employee, :id => 11
      end

      it 'assigns @employees' do
        assigns(:employees).should == [@employee]
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @assigned_employee' do
        assigns(:assigned_employee).should == ['10', '11']
      end

      it 'updates @batch.employee_id' do
        Batch.find(@batch).employee_id.should == '10,11'
      end

      it 'replaces element employee-list with partial template' do
        response.should have_rjs(:replace_html, 'employee-list')
        response.should render_template(:partial => 'employee_list')
      end

      it 'replaces element tutor-list with partial template' do
        response.should have_rjs(:replace_html, 'tutor-list')
        response.should render_template(:partial => 'assigned_tutor_list')
      end
    end

    context '@batch.employee_id is nil' do
      before do
        @batch.employee_id = nil
        get :assign_employee, :id => 11
      end

      it 'assigns @assigned_employee' do
        assigns(:assigned_employee).should == ['11']
      end
    end
  end

  describe 'GET #remove_employee' do
    before do
      @batch.employee_id = '10,11'
      Batch.stub(:find_by_id).and_return(@batch)
      @employee = FactoryGirl.build(:employee)
      Employee.stub(:find_all_by_employee_department_id).and_return([@employee])
      get :remove_employee, :id => 11
    end

    it 'assigns @employees' do
      assigns(:employees).should == [@employee]
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @removed_emps' do
      assigns(:removed_emps).should == '11'
    end

    it 'assigns @assigned_emps' do
      assigns(:assigned_emps).should == '10'
    end

    it 'updates @batch.employee_id' do
      Batch.find(@batch).employee_id.should == '10'
    end

    it 'replaces element employee-list with partial template' do
      response.should have_rjs(:replace_html, 'employee-list')
      response.should render_template(:partial => 'employee_list')
    end

    it 'replaces element tutor-list with partial template' do
      response.should have_rjs(:replace_html, 'tutor-list')
      response.should render_template(:partial => 'assigned_tutor_list')
    end
  end

  describe 'XHR GET #batches_ajax' do
    before do
      Course.stub(:find_by_id).and_return(@course)
      @course.batches.stub(:active).and_return([@batch])
      xhr :get, :batches_ajax, :course_id => 1, :type => 'list'
    end

    it 'assigns @course' do
      assigns(:course).should == @course
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'renders the list template' do
      response.should render_template(:partial => 'list')
    end
  end

  describe 'PRIVATE #init_data' do
    before do
      Batch.stub(:find_by_id).and_return(@batch)
      Course.stub(:find_by_id).and_return(@course)
      controller.stub(:action_name).and_return('show')
      controller.send(:init_data)
    end

    it 'assigns @batch' do
      controller.instance_eval{ @batch }.should == @batch
    end

    it 'assigns @course' do
      controller.instance_eval{ @course }.should == @course
    end
  end
end