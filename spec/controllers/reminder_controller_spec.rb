require 'spec_helper'

describe ReminderController do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)

    @batch = FactoryGirl.build(:batch)
    @reminder = FactoryGirl.build(:reminder, :user => @user, :sender => @user.id, :recipient => @user.id)
  end

  describe 'GET #index' do
    before do
      @reminder1 = FactoryGirl.build(:reminder)
      Reminder.stub(:paginate).and_return([@reminder])
      Reminder.stub(:find_all_by_recipient_and_is_read_and_is_deleted_by_recipient).and_return([@reminder, @reminder1], [@reminder1])
      get :index
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @reminders' do
      assigns(:reminders).should == [@reminder]
    end

    it 'assigns @read_reminders' do
      assigns(:read_reminders).should == [@reminder, @reminder1]
    end

    it 'assigns @new_reminder_count' do
      assigns(:new_reminder_count).should == [@reminder1]
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'POST #create_reminder' do
    before do
      @employee_department = FactoryGirl.build(:employee_department)
      EmployeeDepartment.stub(:all).and_return([@employee_department])
      Reminder.stub(:find_all_by_recipient_and_is_read).and_return([@reminder])
    end

    context 'params[:reminder][:body] && params[:recipients] are present' do
      before { post :create_reminder, :send_to => @user.id, :reminder => {:subject => 'Test Subject', :body => 'Test Body'}, :recipients => @user.id }
      it 'assigns @user' do
        assigns(:user).should == @user
      end

      it 'assigns @departments' do
        assigns(:departments).should == [@employee_department]
      end

      it 'assigns @new_reminder_count' do
        assigns(:new_reminder_count).should == [@reminder]
      end

      it 'assigns @recipients' do
        assigns(:recipients).should == [@user]
      end

      it 'creates Delay Job with params' do
        Delayed::Job.all.count.should == 1
        Delayed::Job.first.handler.should include_text("DelayedReminderJob\nsender_id: #{@user.id}\nrecipient_ids:\n- #{@user.id}\nsubject: Test Subject\nmessage: \nbody: Test Body")
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash1')}"
      end

      it 'redirects to create_reminder action' do
        response.should redirect_to(:controller => 'reminder', :action => 'create_reminder')
      end
    end

    context 'params[:reminder][:body] && params[:recipients] are nil' do
      before { post :create_reminder, :reminder => {} }

      it 'assigns flash[:notice]' do
        flash[:notice].should == "<b>ERROR:</b>#{@controller.t('flash6')}"
      end

      it 'redirects to create_reminder action' do
        response.should redirect_to(:controller => 'reminder', :action => 'create_reminder')
      end
    end
  end

  describe 'GET #select_employee_department' do
    before do
      @employee_department = FactoryGirl.build(:employee_department)
      EmployeeDepartment.stub(:find_all_by_status).and_return([@employee_department])
      get :select_employee_department
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @departments' do
      assigns(:departments).should == [@employee_department]
    end

    it 'renders the select_employee_department partial template' do
      response.should render_template(:partial => 'select_employee_department')
    end
  end

  describe 'GET #select_users' do
    before do
      User.stub(:find_all_by_student).and_return([@user])
      get :select_users
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @to_users' do
      assigns(:to_users).should == [@user.id]
    end

    it 'renders the to_users partial template' do
      response.should render_template(:partial => 'to_users')
    end
  end

  describe 'GET #select_student_course' do
    before do
      Batch.stub(:active).and_return([@batch])
      get :select_student_course
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'renders the select_student_course partial template' do
      response.should render_template(:partial => 'select_student_course')
    end
  end

  describe 'GET #to_employees' do
    context 'params[:dept_id] is present' do
      before do
        @employee = FactoryGirl.build(:employee, :user => @user)
        @employee_department = FactoryGirl.build(:employee_department, :employees => [@employee])
        EmployeeDepartment.stub(:find).and_return(@employee_department)
        get :to_employees, :dept_id => 1
      end

      it 'assigns @to_users' do
        assigns(:to_users).should == [@user.id]
      end

      it 'replaces element to_users with partial template' do
        response.should have_rjs(:replace_html, 'to_users')
        response.should render_template(:partial => 'to_users')
      end
    end

    context 'params[:dept_id] is present' do
      before { get :to_employees }

      it 'replaces element to_employees' do
        response.should have_rjs(:replace_html, 'to_employees')
      end
    end
  end

  describe 'GET #to_students' do
    context 'params[:batch_id] is present' do
      before do
        @student = FactoryGirl.build(:student, :user => @user)
        @batch.students = [@student]
        Batch.stub(:find).and_return(@batch)
        get :to_students, :batch_id => 1
      end

      it 'assigns @to_users' do
        assigns(:to_users).should == [@user.id]
      end

      it 'replaces element to_users2 with partial template' do
        response.should have_rjs(:replace_html, 'to_users2')
        response.should render_template(:partial => 'to_users')
      end
    end

    context 'params[:batch_id] is nil' do
      before { get :to_students }

      it 'replaces element to_user' do
        response.should have_rjs(:replace_html, 'to_user')
      end
    end
  end

  describe 'GET #update_recipient_list' do
    context 'params[:recipients] is present' do
      before { get :update_recipient_list, :recipients => @user.id }

      it 'assigns @recipients' do
        assigns(:recipients).should == [@user]
      end

      it 'replaces element recipient-list with partial template' do
        response.should have_rjs(:replace_html, 'recipient-list')
        response.should render_template(:partial => 'recipient_list')
      end
    end

    context 'params[:recipients] is nil' do
      before { get :update_recipient_list }

      it 'redirects to user dashboard' do
        response.should redirect_to(:controller => :user, :action => :dashboard)
      end
    end
  end

  describe 'GET #sent_reminder' do
    before do
      Reminder.stub(:paginate).and_return([@reminder])
      Reminder.stub(:find_all_by_recipient_and_is_read).and_return([@reminder])
      get :sent_reminder
    end

    it 'assigns @user' do
      assigns(:user).should == @user
    end

    it 'assigns @sent_reminders' do
      assigns(:sent_reminders).should == [@reminder]
    end

    it 'assigns @new_reminder_count' do
      assigns(:new_reminder_count).should == [@reminder]
    end

    it 'renders the sent_reminder template' do
      response.should render_template('sent_reminder')
    end
  end

  describe 'GET #view_sent_reminder' do
    before do
      Reminder.stub(:find).and_return(@reminder)
      get :view_sent_reminder
    end

    it 'assigns @sent_reminder' do
      assigns(:sent_reminder).should == @reminder
    end

    it 'renders the view_sent_reminder template' do
      response.should render_template('view_sent_reminder')
    end
  end

  describe 'DELETE #delete_reminder_by_sender' do
    before do
      @reminder.update_attribute(:is_deleted_by_sender, false)
      delete :delete_reminder_by_sender, :id2 => @reminder.id
    end

    it 'assigns @sent_reminder' do
      assigns(:sent_reminder).should == @reminder
    end

    it 'updates reminder.is_deleted_by_sender to true' do
      Reminder.find(@reminder).should be_is_deleted_by_sender
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash2')}"
    end

    it 'redirects to action sent_reminder' do
      response.should redirect_to(:action => 'sent_reminder')
    end
  end

  describe 'POST #view_reminder' do
    before { @reminder.update_attribute(:is_read, false) }

    context 'params[:reminder][:body] is present' do
      before { post :view_reminder, :id2 => @reminder, :reminder => {:subject => 'Test Subject', :body => 'Test Body'} }

      it 'assigns @new_reminder' do
        assigns(:new_reminder).should == @reminder
      end

      it 'assigns @sender' do
        assigns(:sender).should == @user
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash3')}"
      end

      it 'creates Reminder with params' do
        Reminder.find(:first, :conditions => {:sender => @user.id, :recipient => @user.id, :subject => 'Test Subject', :body => 'Test Body', :is_read => false, :is_deleted_by_sender => false, :is_deleted_by_recipient => false}).should be_present
      end

      it 'redirects to view_reminder' do
        response.should redirect_to(:controller => 'reminder', :action => 'view_reminder', :id2 => @reminder)
      end
    end

    context 'params[:reminder][:body] is nil' do
      before { post :view_reminder, :id2 => @reminder, :reminder => {} }

      it 'assigns flash[:notice]' do
        flash[:notice].should == "<b>ERROR:</b>#{@controller.t('flash4')}"
      end

      it 'redirects to view_reminder' do
        response.should redirect_to(:controller => 'reminder', :action => 'view_reminder', :id2 => @reminder)
      end
    end
  end

  describe 'GET #mark_unread' do
    before do
      @reminder.update_attribute(:is_read, true)
      get :mark_unread, :id2 => @reminder
    end

    it 'update reminder.is_read to false' do
      Reminder.find(@reminder).should_not be_is_read
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash5')}"
    end

    it 'redirects to action index' do
      response.should redirect_to(:controller => 'reminder', :action => 'index')
    end
  end

  describe 'GET #pull_reminder_form' do
    before do
      @employee = FactoryGirl.build(:employee, :user => @user)
      Employee.stub(:find).and_return(@employee)
      get :pull_reminder_form
    end

    it 'assigns @employee' do
      assigns(:employee).should == @employee
    end

    it 'assigns @manager' do
      assigns(:manager).should == @user
    end

    it 'renders the send_reminder partial template' do
      response.should render_template(:partial => 'send_reminder')
    end
  end

  describe 'GET #send_reminder' do
    context 'params[:create_reminder] is present' do
      context 'params[:create_reminder][:message] && params[:create_reminder][:to] are present' do
        before do
          get :send_reminder, :create_reminder => {:from => 'sender@gmail.com', :to => 'recipient@gmail.com', :subject => 'Test Subject', :message => 'Test Massage'}
        end

        it 'creates Reminder with params' do
          Reminder.find(:first, :conditions => {:sender => 'sender@gmail.com', :recipient => 'recipient@gmail.com', :subject => 'Test Subject',
            :body => 'Test Massage', :is_read => false, :is_deleted_by_sender => false, :is_deleted_by_recipient => false}).should be_present
        end

        it 'replaces element error-msg with partial template' do
          response.should have_rjs(:replace_html, 'error-msg')
          response.should include_text("<p class='flash-msg'>#{I18n.t('your_message_sent')}</p>")
        end
      end

      context 'params[:create_reminder][:message] && params[:create_reminder][:to] are nil' do
        before do
          get :send_reminder, :create_reminder => {}
        end

        it 'replaces element error-msg with partial template' do
          response.should have_rjs(:replace_html, 'error-msg')
          response.should include_text("<p class='flash-msg'>#{I18n.t('enter_subject')}</p>")
        end
      end
    end

    context 'params[:create_reminder] is nil' do
      before { get :send_reminder }

      it 'redirects to controller reminder' do
        response.should redirect_to(:controller => :reminder)
      end
    end
  end

  describe 'POST #reminder_actions' do
    before do
      @reminder.update_attributes({:is_deleted_by_recipient => false, :is_read => false})
      Reminder.stub(:find_by_id).and_return(@reminder)
      Reminder.stub(:paginate).and_return([@reminder])
      Reminder.stub(:find_all_by_recipient_and_is_read_and_is_deleted_by_recipient).and_return([@reminder])
    end

    context 'params[:reminder][:action] == delete' do
      before do
        post :reminder_actions, :message_ids => [@reminder.id], :reminder => {:action => 'delete'}, :page => 2
      end

      it 'updates is_deleted_by_recipient and is_read to true' do
        Reminder.find(@reminder).should be_is_deleted_by_recipient
        Reminder.find(@reminder).should be_is_read
      end

      it 'assigns @user' do
        assigns(:user).should == @user
      end

      it 'assigns @reminders' do
        assigns(:reminders).should == [@reminder]
      end

      it 'assigns @new_reminder_count' do
        assigns(:new_reminder_count).should == [@reminder]
      end

      it 'redirects to action index with param page' do
        response.should redirect_to(:action => :index, :page => 2)
      end
    end

    context 'params[:reminder][:action] == read' do
      before do
        post :reminder_actions, :message_ids => [@reminder.id], :reminder => {:action => 'read'}
      end

      it 'updates is_read to true' do
        Reminder.find(@reminder).should be_is_read
      end
    end

    context 'params[:reminder][:action] == unread' do
      before do
        @reminder.update_attribute(:is_read, true)
        post :reminder_actions, :message_ids => [@reminder.id], :reminder => {:action => 'unread'}
      end

      it 'updates is_read to false' do
        Reminder.find(@reminder).should_not be_is_read
      end
    end
  end

  describe 'POST #sent_reminder_delete' do
    before do
      @reminder.update_attribute(:is_deleted_by_sender, false)
      Reminder.stub(:find_by_id).and_return(@reminder)
      Reminder.stub(:paginate).and_return([@reminder])
      Reminder.stub(:find_all_by_recipient_and_is_read).and_return([@reminder])
      post :sent_reminder_delete, :message_ids => [@reminder.id], :page => 2
    end

    it 'updates each reminder.is_deleted_by_sender to true' do
      Reminder.find(@reminder).should be_is_deleted_by_sender
    end

    it 'assigns @sent_reminders' do
      assigns(:sent_reminders).should == [@reminder]
    end

    it 'assigns @new_reminder_count' do
      assigns(:new_reminder_count).should == [@reminder]
    end

    it 'redirects to action index with param page' do
      response.should redirect_to(:action => :sent_reminder, :page => 2)
    end
  end
end