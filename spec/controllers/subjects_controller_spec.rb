require 'spec_helper'

describe SubjectsController do
  before do
    @batch = FactoryGirl.build(:batch)
    @elective_group = FactoryGirl.build(:elective_group)
    @subject = FactoryGirl.build(:subject, :batch => @batch)
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

  describe '#new' do
    context 'GET Request' do
      before do

        ElectiveGroup.stub(:find).and_return(@elective_group)
        get :new, :id2 => 2
      end

      it 'assigns new record to @subject' do
        assigns(:subject).should be_new_record
      end

      it 'assigns @elective_group' do
        assigns(:elective_group).should == @elective_group
      end

      it 'renders the new template' do
        response.should render_template('new')
      end
    end

    context 'XHR Request' do
      before do
        Batch.stub(:find).and_return(@batch)
        xhr :post, :new, :id => 1
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end
    end
  end

  describe 'POST #create' do
    before { Subject.stub(:new).and_return(@subject) }

    context 'successful create' do
      before { Subject.any_instance.expects(:save).returns(true) }

      context 'param elective_group_id is nil' do
        before do
          @subject.batch.stub(:normal_batch_subject).and_return([@subject])
          ElectiveGroup.stub(:find_all_by_batch_id).and_return([@elective_group])
          post :create, :subject => {}
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject]
        end

        it 'assigns @normal_subjects' do
          assigns(:normal_subjects).should == @subject
        end

        it 'assigns @elective_group' do
          assigns(:elective_groups).should == [@elective_group]
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "Subject created successfully!"
        end
      end

      context 'param elective_group_id is present' do
        before do
          @subject.batch.stub(:normal_batch_subject).and_return([@subject])
          ElectiveGroup.stub(:find_all_by_batch_id_and_is_deleted).and_return([@elective_group])
          post :create, :subject => { :elective_group_id => 2 }
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject]
        end

        it 'assigns @elective_group' do
          assigns(:elective_groups).should == [@elective_group]
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "Elective subject created successfully!"
        end
      end
    end

    context 'failed create' do
      before do
        Subject.any_instance.expects(:save).returns(false)
        post :create
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #edit' do
    before do
      Subject.stub(:find).and_return(@subject)
      ElectiveGroup.stub(:find).and_return(@elective_group)
      get :edit, :id2 => 2
    end

    it 'renders the edit template' do
      response.should render_template(:layout => true)
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
  end

  describe 'PUT #update' do
    before { Subject.stub(:find).and_return(@subject) }

    context 'successful update' do
      before { Subject.any_instance.expects(:update_attributes).returns(true) }

      context 'param elective_group_id is nil' do
        before do
          @subject.batch.stub(:normal_batch_subject).and_return([@subject])
          ElectiveGroup.stub(:find_all_by_batch_id).and_return([@elective_group])
          put :update, :id => 2, :subject => {}
        end

        it 'assigns @batch' do
          assigns(:batch).should == @batch
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject]
        end

        it 'assigns @normal_subjects' do
          assigns(:normal_subjects).should == @subject
        end

        it 'assigns @elective_groups' do
          assigns(:elective_groups).should == [@elective_group]
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "Subject updated successfully!"
        end
      end

      context 'param elective_group_id is present' do
        before do
          @subject.batch.stub(:normal_batch_subject).and_return([@subject])
          ElectiveGroup.stub(:find_all_by_batch_id_and_is_deleted).and_return([@elective_group])
          put :update, :id => 2, :subject => { :elective_group_id => 3 }
        end

        it 'assigns @subjects' do
          assigns(:subjects).should == [@subject]
        end

        it 'assigns @elective_groups' do
          assigns(:elective_groups).should == [@elective_group]
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == "Elective subject updated successfully!"
        end
      end
    end

    context 'successful update' do
      before do
        Subject.any_instance.expects(:update_attributes).returns(false)
        put :update
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy' do
    before { Subject.stub(:find).and_return(@subject) }

    context '@subject_exams is nil' do
      before { Exam.stub(:find_by_subject_id).and_return(nil) }

      it 'calls subject inactivate' do
        @subject.should_receive(:inactivate)
        delete :destroy, :id => 2
      end

      it 'assigns flash[:notice]' do
        delete :destroy, :id => 2
        flash[:notice].should == "Subject Deleted successfully!"
      end
    end

    context '@subject_exams is present' do
      before do
        @exam = FactoryGirl.build(:exam)
        Exam.stub(:find_by_subject_id).and_return(@exam)
        delete :destroy, :id => 2
      end

      it 'assigns @error_text' do
        assigns(:error_text).should == "#{@controller.t('cannot_delete_subjects')}"
      end
    end
  end

  describe 'GET #show' do
    context 'param batch_id is nil' do
      before { get :show }

      it 'assigns @subjects' do
        assigns(:subjects).should == []
      end

      it 'renders the show template' do
        response.should render_template('show')
      end
    end

    context 'param batch_id is present' do
      before do
        Batch.stub(:find).and_return(@batch)
        @batch.stub(:normal_batch_subject).and_return([@subject])
        ElectiveGroup.stub(:find_all_by_batch_id_and_is_deleted).and_return([@elective_group])
        get :show, :batch_id => 2
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @subjects' do
        assigns(:subjects).should == [@subject]
      end

      it 'assigns @elective_groups' do
        assigns(:elective_groups).should == [@elective_group]
      end
    end
  end
end