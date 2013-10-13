require 'spec_helper'

describe BatchTransfersController do
  before do
    @batch = FactoryGirl.create(:batch)
    @subject = FactoryGirl.build(:general_subject)
    @elective_group = FactoryGirl.build(:elective_group)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      Batch.stub(:active).and_return([@batch])
      get :index
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'GET #show' do
    before do
      @batch1 = FactoryGirl.build(:batch)
      Batch.stub(:find).and_return(@batch1)
      Batch.stub(:active).and_return([@batch1, @batch])
      get :show
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch1
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end

  describe 'POST #transfer' do
    context 'Request is POST' do
      before { Batch.stub(:find).and_return(@batch) }

      context 'params[:transfer][:to] is present' do
        before { @student = FactoryGirl.create(:student, :batch => @batch) }

        context 'all Student with batch_id is empty' do
          before do
            @batch.update_attribute(:is_active, true)
            Student.stub(:find_all_by_batch_id).and_return([])
            @employees_subject = EmployeesSubject.new
            @subject = FactoryGirl.build(:general_subject, :employees_subjects => [@employees_subject])
            Subject.stub(:find_all_by_batch_id).and_return([@subject])
          end

          it 'deletes employees_subject' do
            @employees_subject.should_receive(:delete)
            post :transfer, :transfer => {:students => [@student.id], :to => 2 }
          end

          context 'POST #transfer' do
            before { post :transfer, :transfer => {:students => [@student.id], :to => 2 } }

            it 'creates batch_student with each param students' do
              BatchStudent.find_by_batch_id(@batch.id).should be_present
            end

            it 'updates student.batch_id to params[:transfer][:to]' do
              Student.find(@student).batch_id.should == 2
            end

            it 'updates student.has_paid_fees to 0' do
              Student.find(@student).should_not be_has_paid_fees
            end

            it 'deactives @batch' do
              Batch.find(@batch).should_not be_is_active
            end

            it 'assigns flash[:notice]' do
              flash[:notice].should == "#{@controller.t('flash1')}"
            end

            it 'redirects to batch_transfers controller' do
              response.should redirect_to(:controller => 'batch_transfers')
            end
          end
        end
      end

      context 'params[:transfer][:to] is nil' do
        before do
          Batch.stub(:active).and_return([@batch])
          post :transfer, :transfer => {}
        end

        it 'assigns @batches' do
          assigns(:batches).should == []
        end

        it 'assigns error to base' do
          @batch.errors[:base].should == "#{I18n.t('select_a_batch_to_continue')}"
        end

        it 'renders the batch_transfers/show template' do
          response.should render_template('batch_transfers/show')
        end
      end
    end

    context 'Request is GET' do
      before { get :transfer, :id => 1 }

      it 'redirects to show action' do
        response.should redirect_to(:action => 'show', :id => 1 )
      end
    end
  end

  describe 'POST #graduation' do
    before do
      @archived_student = FactoryGirl.build(:archived_student)
      ArchivedStudent.stub(:find_by_admission_no).and_return(@archived_student)
      @student = FactoryGirl.create(:student, :admission_no => 99)
    end

    context '@stu is empty' do
      before do
        Student.stub(:find_all_by_batch_id).and_return([])
        @batch.update_attribute(:is_active, true)
        @employees_subject = EmployeesSubject.new
        @batch.stub(:employees_subjects).and_return([@employees_subject])
        post :graduation, :id => @batch.id, :ids => [1], :graduate => {:students => [@student.id]}
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @id_lists' do
        assigns(:id_lists).should == [@archived_student]
      end

      it 'assigns @student_list' do
        assigns(:student_list).should == [@student]
      end

      it 'assigns @admission_list' do
        assigns(:admission_list).should == ['99']
      end

      it 'deactives @batch' do
        Batch.find(@batch).should_not be_is_active
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash2')}"
      end

      it 'redirects to show action' do
        response.should redirect_to(:action => 'graduation', :id => @batch.id, :ids => [99])
      end
    end
  end

  describe 'GET #subject_transfer' do
    before do
      @batch.elective_groups = [@elective_group]
      @batch.stub(:normal_batch_subject).and_return([@subject])
      Subject.stub(:find_all_by_batch_id).and_return([@subject])
      get :subject_transfer, :id => @batch.id
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @elective_groups' do
      assigns(:elective_groups).should == [@elective_group]
    end

    it 'assigns @normal_subjects' do
      assigns(:normal_subjects).should == [@subject]
    end

    it 'assigns @elective_subjects' do
      assigns(:elective_subjects).should == [@subject]
    end

    it 'renders the subject_transfer template' do
      response.should render_template('subject_transfer')
    end
  end

  describe 'GET #get_previous_batch_subjects' do
    context '@previous_batch is present' do
      before do
        @batch1 = FactoryGirl.build(:batch)
        Batch.stub(:first).and_return(@batch1)
        @batch1.stub(:normal_batch_subject).and_return([@subject])
        @batch1.elective_groups.stub(:all).and_return([@elective_group])
        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        get :get_previous_batch_subjects, :id => @batch.id
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @previous_batch' do
        assigns(:previous_batch).should == @batch1
      end

      it 'assigns @previous_batch_normal_subject' do
        assigns(:previous_batch_normal_subject).should == [@subject]
      end

      it 'assigns @elective_groups' do
        assigns(:elective_groups).should == [@elective_group]
      end

      it 'assigns @previous_batch_electives' do
        assigns(:previous_batch_electives).should == [@subject]
      end

      it 'replaces element previous-batch-subjects with partial template' do
        response.should have_rjs(:replace_html, 'previous-batch-subjects')
        response.should render_template(:partial => 'previous_batch_subjects')
      end
    end

    context '@previous_batch is nil' do
      before do
        Batch.stub(:first).and_return(nil)
        get :get_previous_batch_subjects, :id => @batch.id
      end

      it 'replaces element msg with text' do
        response.should have_rjs(:replace_html, 'msg')
        response.should include_text("<p class='flash-msg'>#{I18n.t('batch_transfers.flash4')}</p>")
      end
    end
  end

  describe 'GET #update_batch' do
    before do
      @course = FactoryGirl.build(:course)
      @batch.course = @course
      Batch.stub(:find_all_by_course_id).and_return([@batch])
      get :update_batch
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'replaces element update_batch with partial template' do
      response.should have_rjs(:replace_html, 'update_batch')
      response.should render_template(:partial => 'list_courses')
    end
  end

  describe 'GET #assign_previous_batch_subject' do
    before do
      @subject.id = 6
      Subject.stub(:find_by_id).and_return(@subject)
    end

    context 'sub_exists is empty' do
      before { Subject.stub(:find_by_batch_id_and_name).and_return([]) }

      context 'subject.elective_group_id is nil' do
        before do
          @subject.elective_group_id = nil
          get :assign_previous_batch_subject, :id2 => @batch.id
        end

        it 'creates Subject' do
          Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
          :max_weekly_classes => @subject.max_weekly_classes, :credit_hours => @subject.credit_hours, :elective_group_id => nil, :is_deleted => false}).should be_present
        end

        it 'replaces element prev-subject-name-6' do
          response.should have_rjs(:replace_html, 'prev-subject-name-6')
        end

        it 'replaces element errors with text' do
          response.should have_rjs(:replace_html, 'errors')
          response.should include_text("#{@subject.name}  #{I18n.t('has_been_added_to_batch')}:#{@batch.name}")
        end
      end

      context 'subject.elective_group_id is present' do
        before { @subject.elective_group_id = 5 }

        context 'elect_group_exists is nil' do
          before do
            ElectiveGroup.stub(:find_by_id).and_return(@elective_group)
            ElectiveGroup.stub(:find_by_name_and_batch_id).and_return(nil)
            get :assign_previous_batch_subject, :id2 => @batch.id
          end

          it 'creates ElectiveGroup, Subject' do
            elective_group = ElectiveGroup.first(:conditions => {:name => @elective_group.name, :batch_id => @batch.id, :is_deleted => false})
            elective_group.should be_present
            Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
            :max_weekly_classes => @subject.max_weekly_classes, :credit_hours => @subject.credit_hours, :elective_group_id => elective_group.id, :is_deleted => false}).should be_present
          end
        end

        context 'elect_group_exists is present' do
          before do
            @elective_group.id = 5
            ElectiveGroup.stub(:find).and_return(@elective_group)
            ElectiveGroup.stub(:find_by_name_and_batch_id).and_return(@elective_group)
            get :assign_previous_batch_subject, :id2 => @batch.id
          end

          it 'creates Subject' do
            Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
              :max_weekly_classes => @subject.max_weekly_classes, :credit_hours => @subject.credit_hours, :elective_group_id => 5, :is_deleted => false}).should be_present
          end
        end
      end
    end

    context 'sub_exists is any' do
      before do
        Subject.stub(:find_by_batch_id_and_name).and_return([@subject])
        get :assign_previous_batch_subject, :id2 => @batch.id
      end

      it 'replaces element prev-subject-name-6' do
        response.should have_rjs(:replace_html, 'prev-subject-name-6')
      end

      it 'replaces element errors with text' do
        response.should have_rjs(:replace_html, 'errors')
        response.should include_text("<div class=\\\"errorExplanation\\\"><p>#{@batch.name} #{I18n.t('already_has_subject')} #{@subject.name}</p></div>")
      end
    end
  end

  describe 'GET #assign_all_previous_batch_subjects' do
    before do
      @course = FactoryGirl.build(:course, :batches => [@batch])
      @course.stub(:batches).and_return([@batch])
      @batch.stub(:course).and_return(@course)
      @batch.stub(:subjects).and_return([@subject])
      Batch.stub(:find).and_return(@batch)
      Subject.stub(:find_all_by_batch_id).and_return([@subject])

      @batch.stub(:normal_batch_subject).and_return([@subject])
      @batch.stub(:elective_groups).and_return([@elective_group])
    end

    context 'sub_exists is nil' do
      before { Subject.stub(:find_by_batch_id_and_name).and_return(nil) }

      context 'subject.elective_group_id is nil' do
        before do
          @subject.elective_group_id = nil
          get :assign_all_previous_batch_subjects
        end

        it 'creates Subject' do
          Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
            :max_weekly_classes => @subject.max_weekly_classes, :credit_hours => @subject.credit_hours, :elective_group_id => nil, :is_deleted => false}).should be_present
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @previous_batch' do
          assigns(:previous_batch).should == @batch
        end

        it 'assigns @previous_batch_normal_subject' do
          assigns(:previous_batch_normal_subject).should == [@subject]
        end

        it 'assigns @elective_groups' do
          assigns(:elective_groups).should == [@elective_group]
        end

        it 'assigns @previous_batch_electives' do
          assigns(:previous_batch_electives).should == [@subject]
        end

        it 'replaces element previous-batch-subjects with text' do
          response.should have_rjs(:replace_html, 'previous-batch-subjects')
          response.should include_text("<p>#{I18n.t('subjects_assigned')}</p> ")
        end

        it 'replaces element msg with text' do
          msg = "<li> #{I18n.t('the_subject')} #{@subject.name}  #{I18n.t('has_been_added_to_batch')} #{@batch.name}</li>"
          response.should have_rjs(:replace_html, 'msg')
          response.should include_text("<div class=\\\"flash-msg\\\"><ul>" + msg +"</ul></div>")
        end
      end

      context 'subject.elective_group_id is present' do
        before do
          @subject.elective_group_id = 5
          ElectiveGroup.stub(:find_by_id).and_return(@elective_group)
        end

        context 'elect_group_exists is nil' do
          before do
            ElectiveGroup.stub(:find_by_name_and_batch_id).and_return(nil)
            get :assign_all_previous_batch_subjects
          end

          it 'creates ElectiveGroup, Subject' do
            elect_group = ElectiveGroup.first(:conditions => {:name => @elective_group.name, :batch_id => @batch.id, :is_deleted => false})
            elect_group.should be_present
            Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
              :max_weekly_classes => @subject.max_weekly_classes, :credit_hours => @subject.credit_hours, :elective_group_id => elect_group.id, :is_deleted => false}).should be_present
          end
        end

        context 'elect_group_exists is present' do
          before do
            @elective_group.id = 5
            ElectiveGroup.stub(:find_by_name_and_batch_id).and_return(@elective_group)
            get :assign_all_previous_batch_subjects
          end

          it 'creates Subject' do
            Subject.first(:conditions => {:name => @subject.name, :code => @subject.code, :batch_id => @batch.id, :no_exams => @subject.no_exams,
              :max_weekly_classes => @subject.max_weekly_classes, :credit_hours => @subject.credit_hours, :elective_group_id => 5, :is_deleted => false}).should be_present
          end
        end
      end
    end

    context 'sub_exists is present' do
      before do
        Subject.stub(:find_by_batch_id_and_name).and_return(@subject)
        get :assign_all_previous_batch_subjects
      end

      it 'replaces element errors with text' do
        err = "<li>#{I18n.t('batch')} #{@batch.name} #{I18n.t('already_has_subject')} #{@subject.name}</li>"
        response.should have_rjs(:replace_html, 'errors')
        response.should include_text("<div class=\\\"errorExplanation\\\" ><p>#{I18n.t('following_errors_found')} :</p><ul>" + err + "</ul></div>")
      end
    end
  end

  describe 'XHR POST #new_subject' do
    before do
      Subject.stub(:new).and_return(@subject)
      ElectiveGroup.stub(:find).and_return(@elective_group)
      xhr :post, :new_subject, :id => @batch.id, :id2 => 2
    end

    it 'assigns @subject' do
      assigns(:subject).should == @subject
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @elective_group' do
      assigns(:elective_group).should == @elective_group
    end

    it 'renders the new_subject template' do
      response.should render_template('new_subject')
    end
  end

  describe 'POST #create_subject' do
    before do
      @subject.batch = @batch
      Subject.stub(:new).with({ 'these' => 'params' }).and_return(@subject)
    end

    context 'successful create' do
      before do
        Subject.any_instance.expects(:save).returns(true)
        @batch.stub(:normal_batch_subject).and_return([@subject])
        ElectiveGroup.stub(:find_all_by_batch_id).and_return([@elective_group])
        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        post :create_subject, :subject => { 'these' => 'params' }
      end

      it 'assigns @normal_subjects' do
        assigns(:normal_subjects).should == [@subject]
      end

      it 'assigns @elective_groups' do
        assigns(:elective_groups).should == [@elective_group]
      end

      it 'assigns @elective_subjects' do
        assigns(:elective_subjects).should == [@subject]
      end

      it 'renders the create_subject template' do
        response.should render_template('create_subject')
      end
    end

    context 'successful create' do
      before do
        Subject.any_instance.expects(:save).returns(false)
        post :create_subject, :subject => { 'these' => 'params' }
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end
end