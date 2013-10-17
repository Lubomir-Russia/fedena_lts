require 'spec_helper'

describe UserController do
  before do
    @configuration = FactoryGirl.build(:configuration)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #all' do
    before { get :all }

    it 'assigns @users' do
      assigns(:users).should == [@user]
    end
  end

  describe 'GET #list_user' do
    context 'params[:user_type] == Admin' do
      before do
        @user.update_attribute(:admin, true)
        get :list_user, :user_type => 'Admin'
      end

      it 'assigns @users' do
        assigns(:users).should == [@user]
      end

      it 'replaces element users with partial template' do
        response.should have_rjs(:replace_html, 'users')
        response.should render_template(:partial => 'users')
      end

      it 'replaces element employee_user with partial template' do
        response.should have_rjs(:replace_html, 'employee_user')
      end

      it 'replaces element student_user with partial template' do
        response.should have_rjs(:replace_html, 'student_user')
      end
    end

    context 'params[:user_type] == Employee' do
      context 'found Configuration with HR key' do
        before do

          Configuration.stub(:find_by_config_value).with("HR").and_return(@configuration)
          get :list_user, :user_type => 'Employee'
        end

        it 'replaces element employee_user with partial template' do
          response.should have_rjs(:replace_html, 'employee_user')
          response.should render_template(:partial => 'employee_user')
        end

        it 'replaces element employee_user' do
          response.should have_rjs(:replace_html, 'employee_user')
        end

        it 'replaces element student_user' do
          response.should have_rjs(:replace_html, 'student_user')
        end
      end

      context 'not found Configuration with HR key' do
        before do
          Configuration.stub(:find_by_config_value).with("HR").and_return(nil)
          User.stub(:find_all_by_employee).with(1).and_return([@user])
          get :list_user, :user_type => 'Employee'
        end

        it 'assigns @users' do
          assigns(:users).should == [@user]
        end

        it 'replaces element users with partial template' do
          response.should have_rjs(:replace_html, 'users')
          response.should render_template(:partial => 'users')
        end

        it 'replaces element employee_user' do
          response.should have_rjs(:replace_html, 'employee_user')
        end

        it 'replaces element student_user' do
          response.should have_rjs(:replace_html, 'student_user')
        end
      end
    end

    context 'params[:user_type] == Student' do
      before { get :list_user, :user_type => 'Student'}

      it 'replaces element student_user with partial template' do
        response.should have_rjs(:replace_html, 'student_user')
        response.should render_template(:partial => 'student_user')
      end

      it 'replaces element users' do
        response.should have_rjs(:replace_html, 'users')
      end

      it 'replaces element employee_user' do
        response.should have_rjs(:replace_html, 'employee_user')
      end
    end

    context 'params[:user_type] == Parent' do
      before { get :list_user, :user_type => 'Parent'}

      it 'replaces element student_user with partial template' do
        response.should have_rjs(:replace_html, 'student_user')
        response.should render_template(:partial => 'parent_user')
      end

      it 'replaces element users' do
        response.should have_rjs(:replace_html, 'users')
      end

      it 'replaces element employee_user' do
        response.should have_rjs(:replace_html, 'employee_user')
      end
    end

    context 'params[:user_type] is nil' do
      before { get :list_user}

      it 'assigns @users' do
        assigns(:users).should == ''
      end

      it 'replaces element users with partial template' do
        response.should have_rjs(:replace_html, 'users')
        response.should render_template(:partial => 'users')
      end

      it 'replaces element employee_user' do
        response.should have_rjs(:replace_html, 'employee_user')
      end

      it 'replaces element student_user' do
        response.should have_rjs(:replace_html, 'student_user')
      end
    end
  end

  describe 'GET #list_employee_user' do
    before do
      @employee = FactoryGirl.build(:employee, :user => @user)
      Employee.stub(:find_all_by_employee_department_id).and_return([@employee])
      get :list_employee_user
    end

    it 'assigns @employee' do
      assigns(:employee).should == [@employee]
    end

    it 'assigns @users' do
      assigns(:users).should == [@user]
    end

    it 'replaces element users with partial template' do
      response.should have_rjs(:replace_html, 'users')
      response.should render_template(:partial => 'users')
    end
  end

  describe 'GET #list_student_user' do
    before do
      @student = FactoryGirl.build(:student, :user => @user)
      Student.stub(:find_all_by_batch_id).and_return([@student])
      get :list_student_user
    end

    it 'assigns @student' do
      assigns(:student).should == [@student]
    end

    it 'assigns @users' do
      assigns(:users).should == [@user]
    end

    it 'replaces element users with partial template' do
      response.should have_rjs(:replace_html, 'users')
      response.should render_template(:partial => 'users')
    end
  end

  describe 'GET #list_parent_user' do
    before do
      @guardian = FactoryGirl.build(:guardian, :user => @user)
      Guardian.stub(:all).and_return([@guardian])
      get :list_parent_user
    end

    it 'assigns @guardian' do
      assigns(:guardian).should == [@guardian]
    end

    it 'assigns @users' do
      assigns(:users).should == [@user]
    end

    it 'replaces element users with partial template' do
      response.should have_rjs(:replace_html, 'users')
      response.should render_template(:partial => 'users')
    end
  end

  describe 'POST #change_password' do
    context 'User.authenticate is true' do
      before { User.stub(:authenticate?).and_return(true) }

      context 'new_password == confirm_password' do
        context 'successful update' do
          before do
            User.any_instance.expects(:update_attributes).returns(true)
            post :change_password, :user => {:new_password => '123123', :confirm_password => '123123'}
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('flash9')}"
          end

          it 'redirects to dashboard action' do
            response.should redirect_to(:action => 'dashboard')
          end
        end

        context 'failed update' do
          before do
            User.any_instance.expects(:update_attributes).returns(false)
            post :change_password, :user => {:new_password => '123123', :confirm_password => '123123'}
          end

          it 'assigns flash[:warn_notice]' do
            flash[:warn_notice].should == "<p>#{@user.errors.full_messages}</p>"
          end
        end
      end

      context 'new_password != confirm_password' do
        before { post :change_password, :user => {:new_password => '123123', :confirm_password => '456456'} }

        it 'assigns flash[:warn_notice]' do
          flash[:warn_notice].should == "<p>#{@controller.t('flash10')}</p>"
        end
      end
    end

    context 'User.authenticate is false' do
      before do
        User.stub(:authenticate?).and_return(false)
        post :change_password, :user => {}
      end

      it 'assigns flash[:warn_notice]' do
        flash[:warn_notice].should == "<p>#{@controller.t('flash11')}</p>"
      end
    end
  end

  describe 'POST #user_change_password' do
    before { User.stub(:find_by_username).and_return(@user) }

    context 'params[:user][:new_password] && params[:user][:confirm_password] are present' do
      context 'new_password == confirm_password' do
        context 'successful update' do
          before do
            User.any_instance.expects(:update_attributes).returns(true)
            post :user_change_password, :user => {:new_password => '123123', :confirm_password => '123123'}
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('flash7')}"
          end

          it 'redirects to edit action' do
            response.should redirect_to(:action => "edit", :id => @user.username)
          end
        end

        context 'failed update' do
          before do
            User.any_instance.expects(:update_attributes).returns(false)
            post :user_change_password, :user => {:new_password => '123123', :confirm_password => '123123'}
          end

          it 'renders the user_change_password template' do
            response.should render_template('user_change_password')
          end
        end
      end

      context 'new_password == confirm_password' do
        before { post :user_change_password, :user => {:new_password => '123123', :confirm_password => '456456'} }

        it 'assigns flash[:warn_notice]' do
          flash[:warn_notice].should == "<p>#{@controller.t('flash10')}</p>"
        end
      end
    end

    context 'params[:user][:new_password] && params[:user][:confirm_password] are present' do
      before { post :user_change_password, :user => {} }

      it 'assigns flash[:warn_notice]' do
        flash[:warn_notice].should == "<p>#{@controller.t('flash6')}</p>"
      end
    end
  end

  describe 'POST #create' do
    before do
      Configuration.stub(:available_modules).and_return(['config_value'])
      User.stub(:new).with({ 'these' => 'params' }).and_return(@user)
    end

    context 'successful create' do
      before do
        User.any_instance.expects(:save).returns(true)
        post :create, :user => { 'these' => 'params' }
      end

      it 'assigns @config' do
        assigns(:config).should == ['config_value']
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash17')}"
      end

      it 'redirects to edit action' do
        response.should redirect_to(:controller => 'user', :action => 'edit', :id => @user.username)
      end
    end

    context 'failed create' do
      before do
        User.any_instance.expects(:save).returns(false)
        post :create, :user => { 'these' => 'params' }
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash16')}"
      end
    end
  end

  describe 'DELETE #delete' do
    before do
      User.stub(:find_by_username).and_return(@user)
      @user.stub(:employee_record).and_return(nil)
      User.any_instance.expects(:destroy).returns(true)
      delete :delete
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash12')}"
    end

    it 'redirects to user controller' do
      response.should redirect_to(:controller => 'user')
    end
  end

  describe 'GET #dashboard' do
    before do
      controller.stub!(:login_check)
      Configuration.stub(:available_modules).and_return(['config_value'])
      @employee = FactoryGirl.build(:employee)
      @user.stub(:employee_record).and_return(@employee)
      @user.stub(:is_first_login?).and_return(true)
      controller.stub(:current_user).and_return(@user)
      Configuration.stub(:get_config_value).and_return('1')
      @student = FactoryGirl.build(:student)
    end

    context '@user is student' do
      before do
        @user.stub(:student?).and_return(true)
        Student.stub(:find_by_admission_no).with(@user.username).and_return(@student)
        get :dashboard
      end

      it 'assigns @user' do
        assigns(:user).should == @user
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'assigns @config' do
        assigns(:config).should == ['config_value']
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('first_login_attempt')}"
      end

      it 'redirects to first_login_change_password action' do
        response.should redirect_to(:controller => "user",:action => "first_login_change_password",:id => @user.username)
      end
    end

    context '@user is parent' do
      before do
        @user.stub(:student?).and_return(false)
        @user.stub(:parent?).and_return(true)
        Student.stub(:find_by_admission_no).with(@user.username[1..@user.username.length]).and_return(@student)
        get :dashboard
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end
    end
  end

  describe 'POST #edit' do
    before do
      User.stub(:find_by_username).and_return(@user)
      User.any_instance.expects(:update_attributes).returns(true)
      post :edit
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @current_user' do
      assigns(:current_user).should == @user
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash13')}"
    end

    it 'redirects to profile action' do
      response.should redirect_to(:controller => 'user', :action => 'profile', :id => @user.username)
    end
  end

  describe 'POST #forgot_password' do
    before { Configuration.stub(:find_by_config_key).and_return(@configuration) }

    context 'params[:reset_password] is present' do
      context 'found User with param username' do
        before do
          User.stub(:find_by_username).and_return(@user)
        end

        context 'user.email is present' do
          before do
            @user.should_receive(:save)
            UserNotifier.should_receive(:deliver_forgot_password)
            post :forgot_password, :reset_password => {:username => 'admin'}
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('flash18')}"
          end

          it 'redirects to index action' do
            response.should redirect_to(:action => "index")
          end
        end

        context 'user.email is nil' do
          before do
            @user.email = nil
            post :forgot_password, :reset_password => {:username => 'admin'}
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('flash20')}"
          end
        end
      end

      context 'not found User with param username' do
        before do
          User.stub(:find_by_username).and_return(nil)
          post :forgot_password, :reset_password => {:username => 'admin'}
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('flash19')} #{params[:reset_password][:username]}"
        end
      end
    end
  end

  describe 'POST #login' do
    before do
      controller.stub!(:check_if_loggedin)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
    end

    context 'authenticated_user is present' do
      before do
        User.stub(:new).and_return(@user)
        User.stub(:find_by_username).and_return(@user)
        User.stub(:authenticate?).and_return(true)
      end

      it 'calls successful_user_login' do
        controller.should_receive(:successful_user_login).with(@user)
        post :login, :user => 'admin'
      end
    end

    context 'authenticated_user is nil' do
      before do
        User.stub(:new).and_return(@user)
        User.stub(:find_by_username).and_return(nil)
        User.stub(:authenticate?).and_return(false)
        post :login, :user => 'admin'
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('login_error_message')}"
      end
    end
  end

  describe 'POST #first_login_change_password' do
    before do
      controller.stub!(:login_check)
      User.stub(:find_by_username).and_return(@user)
    end

    context '@setting == "1" && @user.is_first_login?' do
      before do
        Configuration.stub(:get_config_value).and_return('1')
        @user.stub(:is_first_login?).and_return(true)
      end

      context 'new_password == confirm_password' do
        context 'successful update' do
          before do
            User.any_instance.expects(:update_attributes).returns(true)
            post :first_login_change_password, :user => {:new_password => '123123', :confirm_password => '123123'}
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('password_update')}"
          end

          it 'redirects to dashboard action' do
            response.should redirect_to(:controller => "user", :action => "dashboard")
          end
        end

        context 'failed update' do
          before do
            User.any_instance.expects(:update_attributes).returns(false)
            post :first_login_change_password, :user => {:new_password => '123123', :confirm_password => '123123'}
          end

          it 'renders the first_login_change_password template' do
            response.should render_template('first_login_change_password')
          end
        end
      end

      context 'new_password != confirm_password' do
        before { post :first_login_change_password, :user => {:new_password => '123123', :confirm_password => '456456'} }

        it 'assigns @user errors' do
          @user.errors[:password].should == 'and confirm password does not match'
        end

        it 'renders the first_login_change_password template' do
          response.should render_template('first_login_change_password')
        end
      end
    end

    context '@setting != "1" || @user.is_first_login is false' do
      before do
        Configuration.stub(:get_config_value).and_return(nil)
        @user.stub(:is_first_login?).and_return(false)
        post :first_login_change_password, :user => {}
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('not_applicable')}"
      end

      it 'redirects to dashboard action' do
        response.should redirect_to(:controller => "user", :action => "dashboard")
      end
    end
  end

  describe 'POST #logout' do
    before { Rails.cache.should_receive(:delete).twice }

    context 'selected_logout_hook is present' do
      before do
        FedenaPlugin::AVAILABLE_MODULES.stub(:select).and_return([{:name => 'Course'}])
      end

      it 'calls send method' do
        Course.should_receive(:send).with("logout_hook", controller, "/")
        post :logout
      end
    end

    context 'selected_logout_hook is nil' do
      before do
        FedenaPlugin::AVAILABLE_MODULES.stub(:select).and_return([])
        post :logout
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('logged_out')}"
      end

      it 'redirects to login action' do
        response.should redirect_to(:controller => 'user', :action => 'login')
      end
    end
  end

  describe 'GET #profile' do
    before do
      Configuration.stub(:available_modules).and_return(['config_value'])
      controller.stub(:current_user).and_return(@user)
    end

    context '@user is present' do
      before do
        User.stub(:find_by_username).and_return(@user)
        @employee = FactoryGirl.build(:employee)
        Employee.stub(:find_by_employee_number).and_return(@employee)
        @student = FactoryGirl.build(:student)
        Student.stub(:find_by_admission_no).and_return(@student)
        @user.stub(:parent).and_return(true)
        @user.stub(:parent_record).and_return(@student)
        get :profile
      end

      it 'assigns @config' do
        assigns(:config).should == ['config_value']
      end

      it 'assigns @current_user' do
        assigns(:current_user).should == @user
      end

      it 'assigns @username' do
        assigns(:username).should == @user.username
      end

      it 'assigns @user' do
        assigns(:user).should == @user
      end

      it 'assigns @employee' do
        assigns(:employee).should == @employee
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'assigns @ward' do
        assigns(:ward).should == @student
      end

      it 'renders the profile template' do
        response.should render_template('profile')
      end
    end

    context '@user is nil' do
      before do
        User.stub(:find_by_username).and_return(nil)
        get :profile
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash14')}"
      end

      it 'redirects to dashboard action' do
        response.should redirect_to(:action => 'dashboard')
      end
    end
  end

  describe 'POST #reset_password' do
    context 'found User with reset_password_code' do
      before { User.stub(:find_by_reset_password_code).and_return(@user) }

      context 'user.reset_password_code_until > Time.now' do
        before do
          @user.reset_password_code_until = Time.current + 3.days
          @user.reset_password_code = 'ABCD123'
          post :reset_password
        end

        it 'redirects to set_new_password action' do
          response.should redirect_to(:action => 'set_new_password', :id => 'ABCD123')
        end
      end

      context 'user.reset_password_code_until <= Time.now' do
        before do
          @user.reset_password_code_until = Time.current - 3.days
          post :reset_password
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('flash1')}"
        end

        it 'redirects to index action' do
          response.should redirect_to(:action => 'index')
        end
      end
    end

    context 'not found User with reset_password_code' do
      before do
        User.stub(:find_by_reset_password_code).and_return(nil)
        post :reset_password
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash2')}"
      end

      it 'redirects to index action' do
        response.should redirect_to(:action => 'index')
      end
    end
  end

  describe 'GET #search_user_ajax' do
    context 'params[:query] is any' do
      before do
        User.stub(:all).and_return([@user])
        get :search_user_ajax, :query => ['last_name']
      end

      it 'assigns @user' do
        assigns(:user).should == [@user]
      end

      it 'renders the non-layout' do
        response.should render_template(:layout => false)
      end
    end

    context 'params[:query] is nil || params[:query] is empty' do
      before do
        User.stub(:all).and_return([])
        get :search_user_ajax
      end

      it 'assigns @user' do
        assigns(:user).should be_blank
      end
    end
  end

  describe 'POST #set_new_password' do
    context 'found User with reset_password_code' do
      before do
        User.stub(:find_by_reset_password_code).and_return(@user)
      end

      context 'param new_password == confirm_password' do
        before do
          @user.should_receive(:update_attributes)
          @user.should_receive(:clear_menu_cache)
          post :set_new_password, :set_new_password => {:new_password => '123123', :confirm_password => '123123'}
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('flash3')}"
        end

        it 'redirects to index action' do
          response.should redirect_to(:action => 'index')
        end
      end

      context 'param new_password != confirm_password' do
        before do
          @user.reset_password_code = 'ABC123'
          post :set_new_password, :set_new_password => {:new_password => '123123', :confirm_password => '456456'}
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('flash4')}"
        end

        it 'redirects to set_new_password action' do
          response.should redirect_to(:action => 'set_new_password', :id => 'ABC123')
        end
      end
    end

    context 'not found User with reset_password_code' do
      before do
        User.stub(:find_by_reset_password_code).and_return(nil)
        post :set_new_password
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash5')}"
      end

      it 'redirects to index action' do
        response.should redirect_to(:action => 'index')
      end
    end
  end

  describe 'POST #edit_privilege' do
    before do
      User.stub(:find_by_username).and_return(@user)
      Configuration.stub(:find_by_config_value).and_return(@configuration)
      @sms_setting = FactoryGirl.build(:sms_setting)
      SmsSetting.stub(:application_sms_status).and_return(@sms_setting)
      @privilege_tag = FactoryGirl.build(:privilege_tag)
      PrivilegeTag.stub(:all).and_return([@privilege_tag])
      @privilege = FactoryGirl.build(:privilege)
      @user.stub(:privileges).and_return([@privilege])
      Privilege.stub(:find_all_by_id).and_return([@privilege])
      @user.should_receive(:clear_menu_cache)
      post :edit_privilege
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @finance' do
      assigns(:finance).should == @configuration
    end

    it 'assigns @sms_setting' do
      assigns(:sms_setting).should == @sms_setting
    end

    it 'assigns @hr' do
      assigns(:hr).should == @configuration
    end

    it 'assigns @privilege_tags' do
      assigns(:privilege_tags).should == [@privilege_tag]
    end

    it 'assigns @user_privileges' do
      assigns(:user_privileges).should == [@privilege]
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash15')}"
    end

    it 'redirects to profile action' do
      response.should redirect_to(:action => 'profile', :id => @user.username)
    end
  end

  describe 'GET #header_link' do
    before do
      Configuration.stub(:available_modules).and_return(['config_value'])
      @employee = FactoryGirl.build(:employee)
      @student = FactoryGirl.build(:student)
      Student.stub(:find_by_admission_no).and_return(@student)
    end

    context 'found Employee with employee_number' do
      before do
        Employee.stub(:find_by_employee_number).and_return(@employee)
        post :header_link
      end

      it 'assigns @user' do
        assigns(:user).should == @user
      end

      it 'assigns @config' do
        assigns(:config).should == ['config_value']
      end

      it 'assigns @employee' do
        assigns(:employee).should == @employee
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'renders the header_link partial template' do
        response.should render_template(:partial => 'header_link')
      end
    end

    context 'not found Employee with employee_number' do
      before { Employee.stub(:find_by_employee_number).and_return(nil) }

      context 'found Employee first' do
        before do
          Employee.stub(:first).and_return(@employee)
          post :header_link
        end

        it 'assigns @employee' do
          assigns(:employee).should == @employee
        end
      end
    end
  end
end