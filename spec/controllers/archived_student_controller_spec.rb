require 'spec_helper'

describe ArchivedStudentController do
  before do
    @batch = FactoryGirl.build(:batch)
    @archived_student = FactoryGirl.build(:archived_student)
    @subject = FactoryGirl.build(:general_subject)
    @students_subject = FactoryGirl.build(:students_subject)
    @exam_group = FactoryGirl.build(:exam_group)
    @exam = FactoryGirl.build(:exam)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #profile' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      @student_additional_field = FactoryGirl.build(:student_additional_field)
      StudentAdditionalField.stub(:all).and_return([@student_additional_field])
      get :profile
    end

    it 'assigns @current_user' do
      assigns(:current_user).should == @user
    end

    it 'assigns @archived_student' do
      assigns(:archived_student).should == @archived_student
    end

    it 'assigns @additional_fields' do
      assigns(:additional_fields).should == [@student_additional_field]
    end

    it 'renders the profile template' do
      response.should render_template('profile')
    end
  end

  describe 'GET #show' do
    before do
      @archived_student.stub(:photo_data).and_return('photo_data')
      @archived_student.stub(:photo_filename).and_return('photo_filename')
      ArchivedStudent.stub(:find_by_admission_no).and_return(@archived_student)
      controller.should_receive(:send_data)
      get :show
    end

    it 'assigns @student' do
      assigns(:student).should == @archived_student
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end

  describe 'GET #guardians' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      @archived_guardian = FactoryGirl.build(:archived_guardian)
      ArchivedGuardian.stub(:all).and_return([@archived_guardian])
      get :guardians
    end

    it 'assigns @archived_student' do
      assigns(:archived_student).should == @archived_student
    end

    it 'assigns @parents' do
      assigns(:parents).should == [@archived_guardian]
    end

    it 'renders the guardians template' do
      response.should render_template('guardians')
    end
  end

  describe 'DELETE #destroy' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      delete :destroy
    end

    it 'redirects to user dashboard' do
      response.should redirect_to(:controller => 'user', :action => 'dashboard')
    end
  end

  describe 'GET #reports' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      @archived_student.stub(:batch).and_return(@batch)
      @grouped_exam = FactoryGirl.build(:grouped_exam)
      GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
      Subject.stub(:find_all_by_batch_id).and_return([@subject])
      StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
      Subject.stub(:find).and_return(@subject)
      @batch.stub(:exam_groups).and_return([@exam_group])
      @exam_group.should_receive(:result_published?).and_return(true)
      @archived_student.stub(:all_batches).and_return([@batch])
      get :reports
    end

    it 'assigns @student' do
      assigns(:student).should == @archived_student
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @grouped_exams' do
      assigns(:grouped_exams).should == [@grouped_exam]
    end

    it 'assigns @normal_subjects' do
      assigns(:normal_subjects).should == [@subject]
    end

    it 'assigns @student_electives' do
      assigns(:student_electives).should == [@students_subject]
    end

    it 'assigns @elective_subjects' do
      assigns(:elective_subjects).should == [@subject]
    end

    it 'assigns @subjects' do
      assigns(:subjects).should == [@subject, @subject]
    end

    it 'assigns @exam_groups' do
      assigns(:exam_groups).should == [@exam_group]
    end

    it 'assigns @old_batches' do
      assigns(:old_batches).should == [@batch]
    end

    it 'renders the reports template' do
      response.should render_template('reports')
    end
  end

  describe 'GET #consolidated_exam_report' do
    before do
      ExamGroup.stub(:find).and_return(@exam_group)
      get :consolidated_exam_report
    end

    it 'assigns @exam_group' do
      assigns(:exam_group).should == @exam_group
    end

    it 'renders the consolidated_exam_report template' do
      response.should render_template('consolidated_exam_report')
    end
  end

  describe 'GET #consolidated_exam_report_pdf' do
    before do
      ExamGroup.stub(:find).and_return(@exam_group)
      get :consolidated_exam_report
    end

    it 'assigns @exam_group' do
      assigns(:exam_group).should == @exam_group
    end

    it 'renders the consolidated_exam_report pdf template' do
      response.should render_template(:pdf => 'consolidated_exam_report')
    end
  end

  describe 'GET #academic_report' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      Batch.stub(:find).and_return(@batch)
      Subject.stub(:find_all_by_batch_id).and_return([@subject])
      StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
      Subject.stub(:find).and_return(@subject)
    end

    context '@type == grouped' do
      before do
        @grouped_exam = FactoryGirl.build(:grouped_exam)
        GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
        ExamGroup.stub(:find).and_return(@exam_group)
        get :academic_report, :type => 'grouped'
      end

      it 'assigns @student' do
        assigns(:student).should == @archived_student
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @type' do
        assigns(:type).should == 'grouped'
      end

      it 'assigns @grouped_exams' do
        assigns(:grouped_exams).should == [@grouped_exam]
      end

      it 'assigns @exam_groups' do
        assigns(:exam_groups).should == [@exam_group]
      end

      it 'assigns @subjects' do
        assigns(:subjects).should == [@subject, @subject]
      end

      it 'renders the academic_report template' do
        response.should render_template('academic_report')
      end
    end

    context '@type != grouped' do
      before do
        ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
        get :academic_report
      end

      it 'assigns @exam_groups' do
        assigns(:exam_groups).should == [@exam_group]
      end
    end
  end

  describe 'GET #student_report' do
    before do
      controller.stub!(:login_check)
      @configuration = FactoryGirl.build(:configuration)
      Configuration.stub(:find_by_config_key).and_return(@configuration)
      ArchivedStudent.stub(:find).and_return(@archived_student)
      Batch.stub(:find).and_return(@batch)
    end

    context '@config.config_value != Daily' do
      before do
        @configuration.config_value = nil
        @timetable_entry = FactoryGirl.build(:timetable_entry)
        @batch.stub(:subject_hours).and_return({Date.current => [@timetable_entry, @timetable_entry]})
        @subject_leave = FactoryGirl.build(:subject_leave)
        SubjectLeave.stub(:all).and_return([@subject_leave])
      end

      context '@student.created_at.to_date > @batch.ended_on' do
        before do
          @batch.started_on = Date.new(2013,1,2)
          @archived_student.stub(:created_at).and_return(Date.new(2013,1,7))
          @batch.ended_on = Date.new(2013,1,5)
          get :student_report
        end

        it 'assigns @config' do
          assigns(:config).should == @configuration
        end

        it 'assigns @student' do
          assigns(:student).should == @archived_student
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @start_date' do
          assigns(:start_date).should == Date.new(2013,1,2)
        end

        it 'assigns @end_date' do
          assigns(:end_date).should == Date.new(2013,1,5)
        end

        it 'assigns @academic_days' do
          assigns(:academic_days).should == 2
        end

        it 'assigns @student_leaves' do
          assigns(:student_leaves).should == [@subject_leave]
        end

        it 'assigns @leaves' do
          assigns(:leaves).should == 1
        end

        it 'assigns @attendance = 2 - 1' do
          assigns(:attendance).should == 1
        end

        it 'assigns @percent = (1/2)*100' do
          assigns(:percent).should == 50
        end

        it 'renders the student_report template' do
          response.should render_template('student_report')
        end
      end

      context '@student.created_at.to_date <= @batch.ended_on' do
        before do
          @batch.started_on = Date.new(2013,1,2)
          @archived_student.stub(:created_at).and_return(Date.new(2013,1,4))
          @batch.ended_on = Date.new(2013,1,5)
          get :student_report
        end

        it 'assigns @end_date' do
          assigns(:end_date).should == Date.new(2013,1,4).to_date
        end
      end
    end

    context '@config.config_value == Daily' do
      before do
        @configuration.config_value = 'Daily'
        @archived_student.created_at = Date.new(2013,1,7)
        @batch.started_on = Date.new(2013,1,2)
        @batch.ended_on = Date.new(2013,1,5)
        @attendance = FactoryGirl.build(:attendance)
        Attendance.stub(:all).and_return([@attendance])
        Attendance.stub(:count).and_return(1)
        @batch.stub(:academic_days).and_return(Date.new(2013,1,1)..Date.new(2013,1,4))
        get :student_report
      end

      it 'assigns @student_leaves' do
        assigns(:student_leaves).should == [@attendance]
      end

      it 'assigns @academic_days' do
        assigns(:academic_days).should == 4
      end

      it 'assigns @leaves' do
        assigns(:leaves).should == 2
      end

      it 'assigns @attendance' do
        assigns(:attendance).should == 2
      end

      it 'assigns @percent' do
        assigns(:percent).should == 50
      end
    end
  end

  describe 'GET #generated_report' do
    before { controller.stub!(:open_flash_chart_object) }

    context 'params[:student] is nil' do
      before do
        ExamGroup.stub(:find).and_return(@exam_group)
        @exam_group.stub(:batch).and_return(@batch)
        @student = FactoryGirl.build(:student)
        @batch.stub(:students).and_return([@student])
        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
        Subject.stub(:find).and_return(@subject)
        Exam.stub(:find_by_exam_group_id_and_subject_id).and_return(@exam)
        get :generated_report, :exam_report => {:exam_group_id => 1}
      end

      it 'assigns @exam_group' do
        assigns(:exam_group).should == @exam_group
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @student' do
        assigns(:student).should == @student
      end

      it 'assigns @subjects' do
        assigns(:subjects).should == [@subject, @subject]
      end

      it 'assigns @exams' do
        assigns(:exams).should == [@exam, @exam]
      end

      it 'renders the generated_report template' do
        response.should render_template('generated_report')
      end
    end

    context 'params[:student] is present' do
      before do
        ExamGroup.stub(:find).and_return(@exam_group)
        ArchivedStudent.stub(:find).and_return(@archived_student)
        @archived_student.former_id = 1
        @archived_student.stub(:batch).and_return(@batch)
        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
        Subject.stub(:find).and_return(@subject)
        Exam.stub(:find_by_exam_group_id_and_subject_id).and_return(@exam)
        get :generated_report, :student => 1
      end

      it 'assigns @exam_group' do
        assigns(:exam_group).should == @exam_group
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @student' do
        assigns(:student).should == @archived_student
      end

      it 'assigns @student.id' do
        assigns(:student).id.should == 1
      end

      it 'assigns @subjects' do
        assigns(:subjects).should == [@subject, @subject]
      end

      it 'assigns @exams' do
        assigns(:exams).should == [@exam, @exam]
      end
    end
  end

  describe 'GET #generated_report_pdf' do
    before do
      controller.stub!(:render)
      @config = FactoryGirl.create(:configuration, :config_key => 'InstitutionName', :config_value => '1')
      ExamGroup.stub(:find).and_return(@exam_group)
      ArchivedStudent.stub(:find_by_former_id).and_return(@archived_student)
      @archived_student.former_id = 9
      @archived_student.stub(:batch).and_return(@batch)
      Subject.stub(:find_all_by_batch_id).and_return([@subject])
      StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
      Subject.stub(:find).and_return(@subject)
      Exam.stub(:find_by_exam_group_id_and_subject_id).and_return(@exam)
      get :generated_report_pdf
    end

    it 'assigns @config' do
      assigns(:config).should == '1'
    end

    it 'assigns @exam_group' do
      assigns(:exam_group).should == @exam_group
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @student' do
      assigns(:student).should == @archived_student
    end

    it 'assigns @student.id' do
      assigns(:student).id.should == 9
    end

    it 'assigns @subjects' do
      assigns(:subjects).should == [@subject, @subject]
    end

    it 'assigns @exams' do
      assigns(:exams).should == [@exam, @exam]
    end

    it 'renders the generated_report_pdf template' do
      response.should render_template(:pdf => 'generated_report_pdf')
    end
  end

  describe 'GET #generated_report3' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      @archived_student.former_id = 9
      @archived_student.stub(:batch).and_return(@batch)
      Subject.stub(:find).and_return(@subject)
      ExamGroup.stub(:all).and_return([@exam_group])
      @exam_group.stub(:result_published).and_return(true)
      controller.should_receive(:open_flash_chart_object)
      get :generated_report3
    end

    it 'assigns @student' do
      assigns(:student).should == @archived_student
    end

    it 'assigns @student.id' do
      assigns(:student).id.should == 9
    end

    it 'assigns @batch' do
      assigns(:batch).should == @batch
    end

    it 'assigns @subject' do
      assigns(:subject).should == @subject
    end

    it 'assigns @exam_groups' do
      assigns(:exam_groups).should == [@exam_group]
    end

    it 'renders the generated_report3 template' do
      response.should render_template('generated_report3')
    end
  end

  describe 'GET #previous_years_marks_overview' do
    before do
      ArchivedStudent.stub(:find).and_return(@archived_student)
      @archived_student.stub(:all_batches).and_return([@batch])
      controller.should_receive(:open_flash_chart_object)
      get :previous_years_marks_overview, :type => 'type'
    end

    it 'assigns @type' do
      assigns(:type).should == 'type'
    end

    it 'assigns @student' do
      assigns(:student).should == @archived_student
    end

    it 'assigns @all_batches' do
      assigns(:all_batches).should == [@batch]
    end

    it 'renders the previous_years_marks_overview template' do
      response.should render_template('previous_years_marks_overview')
    end
  end

  describe 'GET #generated_report4' do
    context 'params[:student] is present' do
      before do
        ArchivedStudent.stub(:find).and_return(@archived_student)
        @archived_student.stub(:batch).and_return(@batch)

        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
        Subject.stub(:find).and_return(@subject)
      end

      context 'params[:type] == grouped' do
        before do
          @grouped_exam = FactoryGirl.build(:grouped_exam)
          GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
          ExamGroup.stub(:find).and_return(@exam_group)
          get :generated_report4, :student => 1, :type => 'grouped'
        end

        it 'assigns @student' do
          assigns(:student).should == @archived_student
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @type' do
          assigns(:type).should == 'grouped'
        end

        it 'assigns @grouped_exams' do
          assigns(:grouped_exams).should == [@grouped_exam]
        end

        it 'assigns @exam_groups' do
          assigns(:exam_groups).should == [@exam_group]
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject, @subject]
        end

        it 'renders the generated_report4 template' do
          response.should render_template('generated_report4')
        end
      end

      context 'params[:type] != grouped' do
        before do
          ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
          @exam_group.stub(:result_published).and_return(true)
          get :generated_report4, :student => 1
        end

        it 'assigns @exam_groups' do
          assigns(:exam_groups).should == [@exam_group]
        end
      end
    end
  end

  describe 'GET #generated_report4_pdf' do
    context 'params[:student] is present' do
      before do
        controller.stub!(:render)
        ArchivedStudent.stub(:find).and_return(@archived_student)
        @archived_student.stub(:batch).and_return(@batch)

        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
        Subject.stub(:find).and_return(@subject)
      end

      context 'params[:type] == grouped' do
        before do
          @grouped_exam = FactoryGirl.build(:grouped_exam)
          GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
          ExamGroup.stub(:find).and_return(@exam_group)
          get :generated_report4_pdf, :student => 1, :type => 'grouped'
        end

        it 'assigns @student' do
          assigns(:student).should == @archived_student
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @type' do
          assigns(:type).should == 'grouped'
        end

        it 'assigns @grouped_exams' do
          assigns(:grouped_exams).should == [@grouped_exam]
        end

        it 'assigns @exam_groups' do
          assigns(:exam_groups).should == [@exam_group]
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject, @subject]
        end

        it 'renders the generated_report4_pdf template' do
          response.should render_template(:pdf => 'generated_report4_pdf', :orientation => 'Landscape')
        end
      end

      context 'params[:type] != grouped' do
        before do
          ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
          @exam_group.stub(:result_published).and_return(true)
          get :generated_report4_pdf, :student => 1
        end

        it 'assigns @exam_groups' do
          assigns(:exam_groups).should == [@exam_group]
        end
      end
    end
  end
=begin
  describe 'GET #graph_for_generated_report' do
    before do
      ArchivedStudent.stub(:find_by_former_id).and_return(@archived_student)
      ExamGroup.stub(:find).and_return(@exam_group)
      @archived_student.stub(:batch).and_return(@batch)
      Subject.stub(:find_all_by_batch_id).and_return([@subject])
      StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
      Subject.stub(:find).and_return(@subject)

      Exam.stub(:find_by_exam_group_id_and_subject_id).and_return(@exam)
      @subject.code = 'CODE'
      @exam.stub(:class_average_marks).and_return(60)
      @exam_score = FactoryGirl.build(:exam_score, :marks => 70)
      get :graph_for_generated_report
    end

    it '' do
    end
  end
=end
end
