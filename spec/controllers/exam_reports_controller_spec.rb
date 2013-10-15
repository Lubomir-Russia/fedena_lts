require 'spec_helper'

describe ExamReportsController do
  before do
    @course = FactoryGirl.build(:course)
    @batch = FactoryGirl.build(:batch, :course => @course)
    @grouped_exam = FactoryGirl.build(:grouped_exam)
    @subject = FactoryGirl.build(:general_subject)
    @students_subject = FactoryGirl.build(:students_subject)
    @student = FactoryGirl.build(:student)
    @archived_student = FactoryGirl.build(:archived_student, :former_id => 11)
    @exam_group = FactoryGirl.build(:exam_group)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #archived_exam_wise_report' do
    before do
      Course.stub(:active).and_return([@course])
      get :archived_exam_wise_report
    end

    it 'assigns @courses' do
      assigns(:courses).should == [@course]
    end

    it 'assigns @batches' do
      assigns(:batches).should == []
    end

    it 'renders the archived_exam_wise_report template' do
      response.should render_template('archived_exam_wise_report')
    end
  end

  describe 'GET #list_inactivated_batches' do
    context 'params[:course_id] is present' do
      before do
        Course.stub(:find).and_return(@course)
        Batch.stub(:all).and_return([@batch])
        get :list_inactivated_batches, :course_id => 1
      end

      it 'assigns @course' do
        assigns(:course).should == @course
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch]
      end

      it 'replaces element inactive_batches with partial template' do
        response.should have_rjs(:replace_html, 'inactive_batches')
        response.should render_template(:partial => 'inactive_batches')
      end
    end

    context 'params[:course_id] is nil' do
      before do
        get :list_inactivated_batches
      end

      it 'assigns @batches' do
        assigns(:batches).should == []
      end
    end
  end

  describe 'GET #final_archived_report_type' do
    before do
      Batch.stub(:find).and_return(@batch)
      GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
      get :final_archived_report_type
    end

    it 'assigns @grouped_exams' do
      assigns(:grouped_exams).should == [@grouped_exam]
    end

    it 'replaces element archived_report_type with partial template' do
      response.should have_rjs(:replace_html, 'archived_report_type')
      response.should render_template(:partial => 'report_type')
    end
  end

  describe 'POST #archived_batches_exam_report' do
    context 'params[:student] is nil' do
      context 'params[:exam_report][:batch_id] is present' do
        before { Batch.stub(:find).and_return(@batch) }

        context 'batch_students is any' do
          before do
            @batch_student = FactoryGirl.build(:batch_student, :student_id => 10)
            BatchStudent.stub(:find_all_by_batch_id).and_return([@batch_student])
          end

          context 'st is present' do
            before { Student.stub(:find_by_id).and_return(@student) }

            context 'archived_students is any' do
              before do
                ArchivedStudent.stub(:find_all_by_batch_id).and_return([@archived_student])
                Subject.stub(:find_all_by_batch_id).and_return([@subject])
                StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
                Subject.stub(:find).and_return(@subject)
                @subject.should_receive(:no_exams).twice.and_return(false)
                @subject.should_receive(:exam_not_created).twice.and_return(false)
              end

              context '@type == grouped' do
                before do
                  GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
                  ExamGroup.stub(:find).and_return(@exam_group)
                  post :archived_batches_exam_report, :exam_report => {:batch_id => 1}, :type => 'grouped'
                end

                it 'assigns @batch' do
                  assigns(:batch).should == @batch
                end

                it 'assigns @sorted_students' do
                  assigns(:sorted_students).should == [[@student.first_name, 10, @student], [@archived_student.first_name, 11, @archived_student]]
                end

                it 'assigns @students' do
                  assigns(:students).should == [@student, @archived_student]
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
              end

              context '@type != grouped' do
                before do
                  ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
                  post :archived_batches_exam_report, :exam_report => {:batch_id => 1}
                end

                it 'assigns @exam_groups' do
                  assigns(:exam_groups).should == [@exam_group]
                end
              end
            end
          end
        end

        context '@students is empty' do
          before do
            BatchStudent.stub(:find_all_by_batch_id).and_return([])
            ArchivedStudent.stub(:find_all_by_batch_id).and_return([])
            post :archived_batches_exam_report, :exam_report => {:batch_id => 1}
          end

          it 'assigns flash[:notice]' do
            flash[:notice].should == "#{@controller.t('flash1')}"
          end

          it 'redirects to archived_exam_wise_report action' do
            response.should redirect_to(:action => 'archived_exam_wise_report')
          end
        end
      end

      context 'params[:exam_report] is nil' do
        before { post :archived_batches_exam_report }

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('select_a_batch_to_continue')}"
        end

        it 'redirects to archived_exam_wise_report action' do
          response.should redirect_to(:action => 'archived_exam_wise_report')
        end
      end
    end

    context 'params[:student] is present' do
      context 'params[:type] is present' do
        before do
          Batch.stub(:find).and_return(@batch)
          Subject.stub(:find_all_by_batch_id).and_return([@subject])
          StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
          Subject.stub(:find).and_return(@subject)
          @subject.should_receive(:no_exams).twice.and_return(false)
          @subject.should_receive(:exam_not_created).twice.and_return(false)
        end

        context 'params[:type] == grouped' do
          before do
            GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
            ExamGroup.stub(:find).and_return(@exam_group)
          end

          context 'found Student with params id' do
            before do
              Student.stub(:find_by_id).and_return(@student)
              post :archived_batches_exam_report, :student => 1, :type => 'grouped'
            end

            it 'assigns @student' do
              assigns(:student).should == @student
            end

            it 'assigns @@student.id' do
              assigns(:student).id.should == 1
            end

            it 'assigns @batch' do
              assigns(:batch).should == @batch
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

            it 'replaces element grouped_exam_report with partial template' do
              response.should have_rjs(:replace_html, 'grouped_exam_report')
              response.should render_template(:partial => 'grouped_exam_report')
            end
          end

          context 'not found Student with params id' do
            before { Student.stub(:find_by_id).and_return(nil) }

            context 'found ArchivedStudent with former_id' do
              before do
                ArchivedStudent.stub(:find_by_former_id).and_return(@archived_student)
                post :archived_batches_exam_report, :student => 1, :type => 'grouped'
              end

              it 'assigns @student' do
                assigns(:student).should == @archived_student
              end
            end
          end
        end

        context 'params[:type] != grouped' do
          before do
            Student.stub(:find_by_id).and_return(@student)
            ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
            post :archived_batches_exam_report, :student => 1, :type => 'no group'
          end

          it 'assigns @exam_groups' do
            assigns(:exam_groups).should == [@exam_group]
          end
        end
      end

      context 'params[:type] is nil' do
        before { post :archived_batches_exam_report, :student => 1 }

        it 'assigns flash[:notice]' do
          flash[:notice].should == "#{@controller.t('invalid_parameters')}"
        end

        it 'redirects to archived_exam_wise_report action' do
          response.should redirect_to(:action => 'archived_exam_wise_report')
        end
      end
    end
  end

  describe 'POST #archived_batches_exam_report_pdf' do
    before { controller.stub!(:render) }
    context 'params[:student] is nil' do
      before do
        Batch.stub(:find).and_return(@batch)
        @batch_student = FactoryGirl.build(:batch_student, :student_id => 10)
        BatchStudent.stub(:find_all_by_batch_id).and_return([@batch_student])

        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
        Subject.stub(:find).and_return(@subject)
        @subject.should_receive(:no_exams).twice.and_return(false)
        @subject.should_receive(:exam_not_created).twice.and_return(false)
      end

      context 'found Student with BatchStudent.student_id' do
        before { Student.stub(:find_by_id).and_return(@student) }

        context '@type == grouped' do
          before do
            GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
            ExamGroup.stub(:find).and_return(@exam_group)
            post :archived_batches_exam_report_pdf, :exam_report => {:batch_id => 1}, :type => 'grouped'
          end

          it 'assigns @batch' do
            assigns(:batch).should == @batch
          end

          it 'assigns @students' do
            assigns(:students).should == [@student]
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

          it 'renders the archived_batches_exam_report_pdf' do
            #response.should render_template(:pdf => 'archived_batches_exam_report_pdf', :orientation => 'Landscape')
          end
        end

        context '@type != grouped' do
          before do
            ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
            post :archived_batches_exam_report_pdf, :exam_report => {:batch_id => 1}, :type => 'no grouped'
          end

          it 'assigns @exam_groups' do
            assigns(:exam_groups).should == [@exam_group]
          end
        end
      end

      context 'not found Student with BatchStudent.student_id' do
        before { Student.stub(:find_by_id).and_return(nil) }

        context 'found ArchivedStudent with former_id' do
          before do
            ArchivedStudent.stub(:find_by_former_id).and_return(@archived_student)
            ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
            post :archived_batches_exam_report_pdf, :exam_report => {:batch_id => 1}, :type => 'no grouped'
          end

          it 'assigns @students' do
            assigns(:students).should == [@archived_student]
          end
        end
      end
    end

    context 'params[:student] is present' do
      before do
        Batch.stub(:find).and_return(@batch)

        Subject.stub(:find_all_by_batch_id).and_return([@subject])
        StudentsSubject.stub(:find_all_by_student_id).and_return([@students_subject])
        Subject.stub(:find).and_return(@subject)
        @subject.should_receive(:no_exams).twice.and_return(false)
        @subject.should_receive(:exam_not_created).twice.and_return(false)
      end

      context 'found Student with params[:student]' do
        before { Student.stub(:find_by_id).and_return(@student) }

        context 'params[:type] == grouped' do
          before do
            GroupedExam.stub(:find_all_by_batch_id).and_return([@grouped_exam])
            ExamGroup.stub(:find).and_return(@exam_group)
            post :archived_batches_exam_report_pdf, :student => 1, :type => 'grouped'
          end

          it 'assigns @student' do
            assigns(:student).should == @student
          end

          it 'assigns @student.id' do
            assigns(:student).id.should == 1
          end

          it 'assigns @batch' do
            assigns(:batch).should == @batch
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
        end

        context 'params[:type] != grouped' do
          before do
            ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
            post :archived_batches_exam_report_pdf, :student => 1, :type => 'no grouped'
          end

          it 'assigns @exam_groups' do
            assigns(:exam_groups).should == [@exam_group]
          end
        end
      end

      context 'not found Student with params[:student]' do
        before { Student.stub(:find_by_id).and_return(nil) }

        context 'found ArchivedStudent with former_id' do
          before do
            ArchivedStudent.stub(:find_by_former_id).and_return(@archived_student)
            ExamGroup.stub(:find_all_by_batch_id).and_return([@exam_group])
            post :archived_batches_exam_report_pdf, :student => 1, :type => 'no grouped'
          end

          it 'assigns @student' do
            assigns(:student).should == @archived_student
          end
        end
      end
    end
  end

  describe 'GET #consolidated_exam_report' do
    before do
      @exam_group.stub(:batch).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      @batch.stub(:graduated_students).and_return([@student])
      @batch.stub(:archived_students).and_return([@archived_student])
      ExamGroup.stub(:find).and_return(@exam_group)
      get :consolidated_exam_report
    end

    it 'assigns @exam_group' do
      assigns(:exam_group).should == @exam_group
    end

    it 'assigns @active_students' do
      assigns(:active_students).should == [@student, @student]
    end

    it 'assigns @archvied_students' do
      assigns(:archvied_students).should == [@archived_student]
    end

    it 'renders the consolidated_exam_report template' do
      response.should render_template('consolidated_exam_report')
    end
  end

  describe 'GET #consolidated_exam_report_pdf' do
    before do
      controller.stub!(:render)
      @exam_group.stub(:batch).and_return(@batch)
      @batch.stub(:students).and_return([@student])
      @batch.stub(:graduated_students).and_return([@student])
      @batch.stub(:archived_students).and_return([@archived_student])
      ExamGroup.stub(:find).and_return(@exam_group)
      get :consolidated_exam_report_pdf
    end

    it 'assigns @exam_group' do
      assigns(:exam_group).should == @exam_group
    end

    it 'assigns @active_students' do
      assigns(:active_students).should == [@student, @student]
    end

    it 'assigns @archvied_students' do
      assigns(:archvied_students).should == [@archived_student]
    end

    it 'renders the consolidated_exam_report_pdf' do
      response.should render_template(:pdf => 'consolidated_exam_report_pdf', :page_size=> 'A3')
    end
  end
end