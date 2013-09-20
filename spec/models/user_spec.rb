require 'spec_helper'

describe User do

  it { should ensure_length_of(:username).is_at_least(1).is_at_most(20) }
  it { should ensure_length_of(:password).is_at_least(4).is_at_most(40) }
  it { should validate_format_of(:username).not_with('+admin_').with_message(I18n.t('must_contain_only_letters')) }
  it { should validate_format_of(:email).not_with('test@test').with_message(I18n.t('must_be_a_valid_email_address')) }
  it { should validate_presence_of(:role) }
  it { should validate_presence_of(:password) }
  it { should have_and_belong_to_many(:privileges) }
  it { should have_many(:user_events) }
  it { should have_many(:events).through(:user_events) }
  it { should have_one(:student_record).class_name('Student') }
  it { should have_one(:employee_record).class_name('Employee') }

  describe 'validate_uniqueness_of username' do
    context 'not is_deleted?' do
      let!(:user) { FactoryGirl.create(:admin_user) }

      it { should validate_uniqueness_of(:username) }
    end

    context 'is_deleted?' do
      let!(:user) { FactoryGirl.create(:admin_user, :is_deleted => true) }

      it { should_not validate_uniqueness_of(:username) }
    end
  end

  describe 'named_scope' do
    describe '.active' do
      let!(:active_user) { FactoryGirl.create(:admin_user) }
      let!(:inactive_user) { FactoryGirl.create(:admin_user, :is_deleted => true) }

      it 'returns active user' do
        User.active.should == [active_user]
      end
    end

    describe '.inactive' do
      let!(:active_user) { FactoryGirl.create(:admin_user) }
      let!(:inactive_user) { FactoryGirl.create(:admin_user, :is_deleted => true) }

      it 'returns inactive user' do
        User.inactive.should == [inactive_user]
      end
    end
  end

  describe '.user_security' do
    context 'admin_user' do
      let!(:user) { FactoryGirl.create(:admin_user) }

      it 'returns password and role' do
        user.save
        user.hashed_password.should == Digest::SHA1.hexdigest(user.salt + user.password)
        user.admin.should be_true
        user.is_first_login.should be_true
      end
    end

    context 'student_user' do
      let!(:user) { FactoryGirl.create(:student_user) }

      it 'returns password and role' do
        user.save
        user.hashed_password.should == Digest::SHA1.hexdigest(user.salt + user.password)
        user.student.should be_true
        user.is_first_login.should be_true
      end
    end

    context 'employee_user' do
      let!(:user) { FactoryGirl.create(:employee_user) }

      it 'returns password and role' do
        user.save
        user.hashed_password.should == Digest::SHA1.hexdigest(user.salt + user.password)
        user.employee.should be_true
        user.is_first_login.should be_true
      end
    end

    context 'parent_user' do
      let!(:user) { FactoryGirl.create(:parent_user) }

      it 'returns password and role' do
        user.save
        user.hashed_password.should == Digest::SHA1.hexdigest(user.salt + user.password)
        user.parent.should be_true
        user.is_first_login.should be_true
      end
    end
  end

  describe '#full_name' do
    let(:user) { FactoryGirl.create(:admin_user, :first_name => 'ABC', :last_name => '123') }

    it 'returns full name' do
      user.full_name.should == 'ABC 123'
    end
  end

  describe '#check_reminders' do
    let!(:user) { FactoryGirl.create(:employee_user) }
    before { FactoryGirl.create(:reminder, :recipient => user.id, :is_read => true) }
    before { FactoryGirl.create(:reminder, :recipient => user.id) }

    it 'returns number of read reminders' do
      user.check_reminders.should == 1
    end
  end

  describe '.authenticate?' do
    context 'matching username and password' do
      let!(:user) { FactoryGirl.create(:admin_user) }

      it 'returns true' do
        User.authenticate?(user.username, user.password).should be_true
      end
    end

    context 'not matching username or password' do
      let!(:user) { FactoryGirl.create(:admin_user) }

      it 'returns false' do
        User.authenticate?(user.username, 'invalid pass').should be_false
      end
    end
  end

  describe '#random_string' do
    let(:user) { FactoryGirl.create(:admin_user) }

    it 'returns length of string' do
      user.random_string(9).length.should == 9
    end
  end

  describe '#role_name' do
    context 'admin_user' do
      let(:admin_user) { FactoryGirl.create(:admin_user) }

      it 'returns admin role' do
        admin_user.role_name.should == I18n.t('admin')
      end
    end

    context 'employee_user' do
      let(:employee_user) { FactoryGirl.create(:employee_user) }

      it 'returns employee role' do
        employee_user.role_name.should == I18n.t('employee_text')
      end
    end

    context 'student_user' do
      let(:student_user) { FactoryGirl.create(:student_user) }

      it 'returns student role' do
        student_user.role_name.should == I18n.t('student_text')
      end
    end

    context 'parent_user' do
      let(:parent_user) { FactoryGirl.create(:parent_user) }

      it 'returns parent role' do
        parent_user.role_name.should == I18n.t('parent')
      end
    end
  end

  describe '#role_symbols' do
    context 'admin_user' do
      before do
        @admin_user = FactoryGirl.create(:admin_user)
        @admin_user.privileges.find_or_create(:name => 'SubjectMaster')
      end

      it 'returns admin role symbols' do
        @admin_user.role_symbols.should == [:admin, :subject_master]
      end
    end

    context 'employee_user' do
      before do
        @employee_user = FactoryGirl.create(:employee_user)
        @employee_user.privileges.find_or_create(:name => 'SubjectMaster1')
      end

      it 'returns employee role symbols' do
        @employee_user.role_symbols.should == [:employee, :subject_master1]
      end
    end

    context 'student_user' do
      before do
        @student_user = FactoryGirl.create(:student_user)
        @student_user.privileges.find_or_create(:name => 'SubjectMaster2')
      end

      it 'returns student role symbols' do
        @student_user.role_symbols.should == [:student, :subject_master2]
      end
    end

    context 'parent_user' do
      before do
        @parent_user = FactoryGirl.create(:parent_user)
        @parent_user.privileges.find_or_create(:name => 'SubjectMaster3')
      end

      it 'returns parent role symbols' do
        @parent_user.role_symbols.should == [:parent, :subject_master3]
      end
    end
  end

  describe '#parent_record' do
    context 'student is found' do
      before do
        @user = FactoryGirl.create(:student_user)
        @admission_no = @user.username[1..@user.username.length]
        @student = FactoryGirl.create(:student, :admission_no => @admission_no, :user => @user)
      end

      it 'returns parent record' do
        @user.parent_record.should == @student
      end
    end

    context 'student is not found' do
      before do
        @user = FactoryGirl.create(:student_user)
        @student = FactoryGirl.create(:student)
      end

      it 'returns parent record' do
        @user.parent_record.should_not == @student
      end
    end
  end

  describe '#has_subject_in_batch?' do
    context 'user has subject in batch' do
      before do
        @batch    = FactoryGirl.create(:batch)
        @employee = FactoryGirl.create(:employee) 
        @subject  = FactoryGirl.create(:subject, :batch => @batch)
        EmployeesSubject.create(:employee => @employee, :subject => @subject)
      end

      it 'returns true' do
        @employee.user.has_subject_in_batch?(@batch).should be_true
      end
    end

    context 'user has not subject in batch' do
      before do
        @batch    = FactoryGirl.create(:batch)
        @employee = FactoryGirl.create(:employee) 
        @subject  = FactoryGirl.create(:subject, :batch => @batch)
      end

      it 'returns false' do
        @employee.user.has_subject_in_batch?(@batch).should be_false
      end
    end
  end

  describe '#days_events' do
    before { @date = Date.current }

    context 'admin_user' do
      before do
        @admin = FactoryGirl.create(:admin_user)
        @event = FactoryGirl.create(:event)
      end

      it 'returns events' do
        @admin.days_events(@date).should include(@event)
      end
    end

    context 'student_user' do
      before do
        @batch   = FactoryGirl.create(:batch)
        @student = FactoryGirl.create(:student, :batch => @batch)
        @event1  = FactoryGirl.create(:event)
        @event2  = FactoryGirl.create(:event, :is_common => true)
        BatchEvent.create(:event => @event1, :batch => @batch)
      end

      it 'returns events' do
        @student.user.days_events(@date).should include(@event1, @event2)
      end
    end

    context 'parent_user' do
      before do
        @parent  = FactoryGirl.create(:parent_user)
        @batch   = FactoryGirl.create(:batch)
        @student = FactoryGirl.create(:student, :user => @parent, :batch => @batch, :admission_no => @parent.username[1..@parent.username.length])
        @event1  = FactoryGirl.create(:event)
        @event2  = FactoryGirl.create(:event, :is_common => true)
        UserEvent.create(:event => @event1, :user => @parent)
      end

      it 'returns events' do
        @parent.days_events(@date).should include(@event1, @event2)
      end
    end

    context 'employee_user' do
      before do
        @employee = FactoryGirl.create(:employee_user)
        @event1 = FactoryGirl.create(:event, :is_exam => true)
        @event2 = FactoryGirl.create(:event)
        @emp_departments = FactoryGirl.create(:employee_department)
        @employee = FactoryGirl.create(:employee, :user => @employee, :employee_department => @emp_departments)
        EmployeeDepartmentEvent.create(:event => @event2, :employee_department => @emp_departments)
      end

      it 'returns events' do
        @employee.user.days_events(@date).should include(@event1, @event2)
      end
    end
  end

  describe '#next_event' do
    before do
      @date = Date.current
      @next_date = @date + 1.days
    end

    context 'admin_user' do
      context 'current event' do
        before do
          @admin = FactoryGirl.create(:admin_user)
          @event = FactoryGirl.create(:event)
        end

        it 'returns next_date' do
          @admin.next_event(@date).should == @next_date
        end
      end

      context 'past event' do
        before do
          @admin = FactoryGirl.create(:admin_user)
          @event = FactoryGirl.create(:event,
            :start_date => Date.current - 3.days,
            :end_date => Date.current - 2.days)
        end

        it 'returns nil' do
          @admin.next_event(@date).should == ''
        end
      end
    end

    context 'student_user' do
      context 'start_date <= date' do
        before do
          @batch = FactoryGirl.create(:batch)
          @student = FactoryGirl.create(:student, :batch => @batch)
          @event = FactoryGirl.create(:event)
          BatchEvent.create(:event => @event, :batch => @batch)
        end

        it 'returns next_date' do
          @student.user.next_event(@date).should == @next_date
        end
      end

      context 'start_date > date' do
        before do
          @batch = FactoryGirl.create(:batch)
          @student = FactoryGirl.create(:student, :batch => @batch)
          @event = FactoryGirl.create(:event,
            :start_date => Date.current + 2.days,
            :end_date => Date.current + 3.days)
          BatchEvent.create(:event => @event, :batch => @batch)
        end

        it 'returns start_date' do
          @student.user.next_event(@date).should == @event.start_date
        end
      end
    end

    context 'parent user' do
      context 'start_date <= date' do
        before do
          @parent = FactoryGirl.create(:parent_user)
          @batch = FactoryGirl.create(:batch)
          @student = FactoryGirl.create(:student, 
            :batch => @batch,
            :user => @parent,
            :admission_no => @parent.username[1..@parent.username.length])
          @event = FactoryGirl.create(:event)
          UserEvent.create(:event => @event, :user => @parent)
          BatchEvent.create(:event => @event, :batch => @batch)
        end

        it 'returns next_date' do
          @student.user.next_event(@date).should == @next_date
        end
      end

      context 'start_date > date' do
        before do
          @parent = FactoryGirl.create(:parent_user)
          @batch = FactoryGirl.create(:batch)
          @student = FactoryGirl.create(:student, 
            :batch => @batch,
            :user => @parent,
            :admission_no => @parent.username[1..@parent.username.length])
          @event = FactoryGirl.create(:event,
            :start_date => Date.current + 2.days,
            :end_date => Date.current + 3.days)
          UserEvent.create(:event => @event, :user => @parent)
          BatchEvent.create(:event => @event, :batch => @batch)
        end

        it 'returns start_date' do
          @parent.next_event(@date).should == @event.start_date
        end
      end
    end

    context 'employee_user' do
      context 'start_date <= date' do
        before do
          @emp_departments = FactoryGirl.create(:employee_department)
          @employee = FactoryGirl.create(:employee, :employee_department => @emp_departments)
          @event = FactoryGirl.create(:event, :is_exam => true)
          EmployeeDepartmentEvent.create(:event => @event, :employee_department => @emp_departments)
        end

        it 'returns next_date' do
          @employee.user.next_event(@date).should == @next_date
        end
      end

      context 'start_date > date' do
        before do
          @emp_departments = FactoryGirl.create(:employee_department)
          @employee = FactoryGirl.create(:employee, :employee_department => @emp_departments)
          @event = FactoryGirl.create(:event,
            :is_exam => true,
            :start_date => Date.current + 2.days,
            :end_date => Date.current + 3.days)
          EmployeeDepartmentEvent.create(:event => @event, :employee_department => @emp_departments)
        end

        it 'returns start_date' do
          @employee.user.next_event(@date).should == @event.start_date
        end
      end
    end
  end

  describe '#soft_delete' do
    let(:user) { FactoryGirl.create(:employee_user) }

    it 'returns result' do
      user.soft_delete
      user.should be_is_deleted
    end
  end
end