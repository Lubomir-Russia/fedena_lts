require 'spec_helper'

describe CoursesController do
  before do
    @user       = Factory.create(:admin_user)
    @batch = FactoryGirl.create(:batch)
    @course     = FactoryGirl.create(:course, :batches => [@batch])
    @batch_group = FactoryGirl.build(:batch_group, :id => 99, :course => @course)
    @subject_amount = FactoryGirl.build(:subject_amount, :course => @course)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      Course.expects(:active).returns(@course)
      get :index
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'GET #show' do
    before do
      get :show, :id => @course
    end

    it 'renders the show template' do
      response.should render_template('show')
    end

    it 'assigns the requested course as @course' do
      assigns(:course).should == @course
    end
  end

  describe 'GET #new' do
    before do
      get :new
    end

    it 'renders the new template' do
      response.should render_template('new')
    end
  end

  describe 'GET #edit' do
    before do
      get :edit, :id => @course
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end
  end

  describe 'POST #create' do
    before do
      Course.stub(:new).with({ 'these' => 'params' }).and_return(@course)
    end

    context 'successful create' do
      before do
        Course.any_instance.expects(:save).returns(true)
        post :create, :course => { 'these' => 'params' }
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash1')}"
      end

      it 'redirects to the manage_course' do
        response.should redirect_to(:controller => 'courses', :action => 'manage_course')
      end
    end

    context 'failed create' do
      before do
        Course.any_instance.expects(:save).returns(false)
        post :create, :course => { 'these' => 'params' }
      end

      it 'renders the new template' do
        response.should render_template('new')
      end

      it 'assigns @grade_types' do
        assigns(:grade_types).should == Course.grading_types_as_options
      end
    end
  end

  describe 'GET #manage_course' do
    before do
      Course.stub(:active).and_return(@course)
      get :manage_course
    end

    it 'assigns @courses' do
      assigns(:courses).should == @course
    end

    it 'renders the manage_course template' do
      response.should render_template('manage_course')
    end
  end

  describe 'GET #assign_subject_amount' do
    before do
      @subject = FactoryGirl.build(:general_subject, :code => 'SUB1')
      @batch.subjects = [@subject]
    end

    context 'successful create' do
      before do
        SubjectAmount.any_instance.expects(:valid?).returns(true)
        post :assign_subject_amount, :id => @course.id, :subject_amount => {:code => 'SUB2'}
      end

      it 'assigns @course' do
        assigns(:course).should == @course
      end

      it 'assigns @subjects with param' do
        assigns(:subjects).should == ['SUB1']
      end

      it 'assigns @subject_amounts' do
        assigns(:subject_amounts).should == [SubjectAmount.first]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Subject amount saved successfully'
      end

      it 'redirects to assign_subject_amount_courses_path' do
        response.should redirect_to(assign_subject_amount_courses_path(:id => @course.id))
      end
    end

    context 'failed create' do
      before do
        SubjectAmount.any_instance.expects(:valid?).returns(false)
        post :assign_subject_amount, :id => @course.id, :subject_amount => {:code => 'SUB2'}
      end

      it 'renders the assign_subject_amount template' do
        response.should render_template('assign_subject_amount')
      end
    end
  end

  describe 'POST #edit_subject_amount' do
    before do
      SubjectAmount.stub(:find).and_return(@subject_amount)
      @subject = FactoryGirl.build(:general_subject, :code => 'SUB1')
      @batch.subjects = [@subject]
    end

    context 'successful update' do
      before do
        SubjectAmount.any_instance.expects(:update_attributes).returns(true)
        post :edit_subject_amount
      end

      it 'assigns @subject_amount' do
        assigns(:subject_amount).should == @subject_amount
      end

      it 'assigns @course' do
        assigns(:course).should == @course
      end

      it 'assigns @subjects' do
        assigns(:subjects).should == ['SUB1']
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Subject amount has been updated successfully'
      end

      it 'redirects to assign_subject_amount_courses_path' do
        response.should redirect_to(assign_subject_amount_courses_path(:id => @course.id))
      end
    end

    context 'failed update' do
      before do
        SubjectAmount.any_instance.expects(:update_attributes).returns(false)
        post :edit_subject_amount
      end

      it 'renders the edit_subject_amount template' do
        response.should render_template('edit_subject_amount')
      end
    end
  end

  describe 'DELETE #destroy_subject_amount' do
    before { SubjectAmount.stub(:find).and_return(@subject_amount) }

    it 'calls destroy' do
      @subject_amount.should_receive(:destroy)
      delete :destroy_subject_amount
    end

    context 'DELETE #destroy_subject_amount' do
      before { delete :destroy_subject_amount }

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Subject amount has been destroyed sucessfully'
      end

      it 'redirects to assign_subject_amount_courses_path' do
        response.should redirect_to(assign_subject_amount_courses_path(:id => @course.id))
      end
    end
  end

  describe 'GET #manage_batches' do
    before { get :manage_batches }

    it 'renders the manage_batches template' do
      response.should render_template('manage_batches')
    end
  end

  describe 'GET #grouped_batches' do
    before do
      Course.stub(:find).and_return(@course)
      @course.batch_groups = [@batch_group]
      @course.stub(:active_batches).and_return([@batch])
      get :grouped_batches
    end

    it 'assigns @course' do
      assigns(:course).should == @course
    end

    it 'assigns @batch_groups' do
      assigns(:batch_groups).should == [@batch_group]
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'assigns new record as @batch_group' do
      assigns(:batch_group).should be_new_record
    end

    it 'renders the grouped_batches template' do
      response.should render_template('grouped_batches')
    end
  end

  describe 'POST #create_batch_group' do
    before do
      BatchGroup.stub(:new).and_return(@batch_group)
      Course.stub(:find).and_return(@course)
      @course.batch_groups = [@batch_group]
    end

    context 'params[:batch_ids] is any && @batch_group is valid' do
      before do
        BatchGroup.any_instance.expects(:save).returns(true)
        @batch1 = FactoryGirl.create(:batch)
        @course.stub(:active_batches).and_return([@batch, @batch1])
        post :create_batch_group, :batch_ids => [@batch.id]
      end

      it 'creates GroupedBatch with each param batch_ids' do
        GroupedBatch.all.count.should == 1
        GroupedBatch.find_by_batch_group_id_and_batch_id(@batch_group.id, @batch.id).should be_present
      end

      it 'assigns @batch_groups' do
        assigns(:batch_groups).should == [@batch_group]
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch1]
      end

      it 'replaces element category-list with partial template' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'batch_groups')
      end

      it 'replaces element flash with text' do
        response.should have_rjs(:replace_html, 'flash')
        response.body.should include_text("<p class=\\\"flash-msg\\\"> Batch Group created successfully. </p>")
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element class_form with partial template' do
        response.should have_rjs(:replace_html, 'class_form')
        response.should render_template(:partial => 'batch_group_form')
      end
    end

    context '@batch_group is invalid' do
      before do
        BatchGroup.any_instance.expects(:save).returns(false)
        post :create_batch_group
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element flash' do
        response.should have_rjs(:replace_html, 'flash')
      end
    end
  end

  describe 'GET #edit_batch_group' do
    before do
      BatchGroup.stub(:find).and_return(@batch_group)
      get :edit_batch_group
    end

    it 'assigns @batch_group' do
      assigns(:batch_group).should == @batch_group
    end

    it 'assigns @course' do
      assigns(:course).should == @course
    end

    it 'assigns @assigned_batches' do
      assigns(:assigned_batches).should == []
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'replaces element class_form with partial template' do
      response.should have_rjs(:replace_html, 'class_form')
      response.should render_template(:partial => 'batch_group_edit_form')
    end

    it 'replaces element errors with partial template' do
      response.should have_rjs(:replace_html, 'errors')
      response.should render_template(:partial => 'form_errors')
    end

    it 'replaces element flash' do
      response.should have_rjs(:replace_html, 'flash')
    end
  end

  describe 'PUT #update_batch_group' do
    before { BatchGroup.stub(:find).and_return(@batch_group) }

    context 'successful update' do
      before do
        BatchGroup.any_instance.expects(:update_attributes).returns(true)
        @batch1 = FactoryGirl.create(:batch)
        @course.stub(:active_batches).and_return([@batch, @batch1])
        @course.stub(:batch_groups).and_return([@batch_group])
        put :update_batch_group, :batch_ids => [@batch.id]
      end

      it 'creates GroupedBatch with each param batch_ids' do
        GroupedBatch.all.count.should == 1
        GroupedBatch.find_by_batch_group_id_and_batch_id(@batch_group.id, @batch.id).should be_present
      end

      it 'assigns new record to @batch_group' do
        assigns(:batch_group).should be_new_record
      end

      it 'assigns @batch_groups' do
        assigns(:batch_groups).should == [@batch_group]
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch1]
      end

      it 'replaces element category-list with partial template' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'batch_groups')
      end

      it 'replaces element flash with text' do
        response.should have_rjs(:replace_html, 'flash')
        response.body.should include_text("<p class=\\\"flash-msg\\\"> Batch Group updated successfully. </p>")
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element class_form with partial template' do
        response.should have_rjs(:replace_html, 'class_form')
        response.should render_template(:partial => 'batch_group_form')
      end
    end

    context 'falied update' do
      before do
        BatchGroup.any_instance.expects(:update_attributes).returns(false)
        put :update_batch_group
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element flash' do
        response.should have_rjs(:replace_html, 'flash')
      end
    end
  end

  describe 'DELETE #delete_batch_group' do
    before { BatchGroup.stub(:find).and_return(@batch_group) }

    it 'calls destroy' do
      @batch_group.should_receive(:destroy)
      delete :delete_batch_group
    end

    context 'DELETE #delete_batch_group' do
      before do
        @course.stub(:batch_groups).and_return([@batch_group])
        delete :delete_batch_group
      end

      it 'assigns new record to @batch_group' do
        assigns(:batch_group).should be_new_record
      end

      it 'assigns @batch_groups' do
        assigns(:batch_groups).should == [@batch_group]
      end

      it 'assigns @batches' do
        assigns(:batches).should == [@batch]
      end

      it 'replaces element category-list with partial template' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'batch_groups')
      end

      it 'replaces element flash with text' do
        response.should have_rjs(:replace_html, 'flash')
        response.body.should include_text("<p class=\\\"flash-msg\\\"> Batch Group deleted successfully. </p>")
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element class_form with partial template' do
        response.should have_rjs(:replace_html, 'class_form')
        response.should render_template(:partial => 'batch_group_form')
      end
    end
  end

  describe 'GET #update_batch' do
    before do
      Batch.stub(:find_all_by_course_id_and_is_deleted_and_is_active).and_return([@batch])
      get :update_batch
    end

    it 'assigns @batch' do
      assigns(:batch).should == [@batch]
    end

    it 'replaces element update_batch with partial template' do
      response.should have_rjs(:replace_html, 'update_batch')
      response.should render_template(:partial => 'update_batch')
    end
  end

  describe '#find_course' do
    before { Course.stub(:find).and_return(@course) }

    it 'assigns @course' do
      controller.send(:find_course)
      controller.instance_eval{ @course }.should == @course
    end
  end
end
