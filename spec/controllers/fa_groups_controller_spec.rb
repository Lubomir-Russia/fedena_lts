require 'spec_helper'

describe FaGroupsController do
  before do
    @fa_group = FactoryGirl.build(:fa_group)
    @fa_criteria = FactoryGirl.build(:fa_criteria, :fa_group => @fa_group)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      FaGroup.stub(:active).and_return([@fa_group])
      get :index
    end

    it 'assigns @fa_groups' do
      assigns(:fa_groups).should == [@fa_group]
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'GET #new' do
    before do
      @cce_exam_category = FactoryGirl.build(:cce_exam_category)
      @cce_grade_set = FactoryGirl.build(:cce_grade_set)
      CceExamCategory.stub(:all).and_return([@cce_exam_category])
      CceGradeSet.stub(:all).and_return([@cce_grade_set])
      get :new
    end

    it 'assigns new record as @fa_group' do
      assigns(:fa_group).should be_new_record
    end

    it 'assigns @exam_categories' do
      assigns(:exam_categories).should == [@cce_exam_category]
    end

    it 'assigns @grade_sets' do
      assigns(:grade_sets).should == [@cce_grade_set]
    end

    it 'renders the new template' do
      response.should render_template('new')
    end
  end

  describe 'POST #create' do
    before { FaGroup.stub(:new).with({ 'these' => 'params' }).and_return(@fa_group) }

    context 'successful create' do
      before do
        FaGroup.any_instance.expects(:save).returns(true)
        FaGroup.stub(:active).and_return([@fa_group])
        post :create, :fa_group => { 'these' => 'params' }
      end

      it 'assigns @fa_groups' do
        assigns(:fa_groups).should == [@fa_group]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'FA Group created successfully.'
      end

      it 'renders the create template' do
        response.should render_template('create')
      end
    end

    context 'failed create' do
      before do
        FaGroup.any_instance.expects(:save).returns(false)
        post :create, :fa_group => { 'these' => 'params' }
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #show' do
    before do
      @fa_group.fa_criterias.stub(:active).and_return([@fa_criteria])
      FaGroup.stub(:find).and_return(@fa_group)
      get :show
    end

    it 'assigns @fa_group' do
      assigns(:fa_group).should == @fa_group
    end

    it 'assigns @fa_criterias' do
      assigns(:fa_criterias).should == [@fa_criteria]
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end

  describe 'GET #edit' do
    before do
      FaGroup.stub(:find).and_return(@fa_group)
      @cce_exam_category = FactoryGirl.build(:cce_exam_category)
      @cce_grade_set = FactoryGirl.build(:cce_grade_set)
      CceExamCategory.stub(:all).and_return([@cce_exam_category])
      CceGradeSet.stub(:all).and_return([@cce_grade_set])
      get :edit
    end

    it 'assigns @fa_group' do
      assigns(:fa_group).should == @fa_group
    end

    it 'assigns @exam_categories' do
      assigns(:exam_categories).should == [@cce_exam_category]
    end

    it 'assigns @grade_sets' do
      assigns(:grade_sets).should == [@cce_grade_set]
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end
  end

  describe 'PUT #update' do
    before { FaGroup.stub(:find).and_return(@fa_group) }

    context 'successful update' do
      before do
        FaGroup.any_instance.expects(:update_attributes).returns(true)
        FaGroup.stub(:active).and_return([@fa_group])
        put :update
      end

      it 'assigns @fa_groups' do
        assigns(:fa_groups).should == [@fa_group]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'FA Group updated successfully.'
      end

      it 'renders the update template' do
        response.should render_template('update')
      end
    end

    context 'failed update' do
      before do
        FaGroup.any_instance.expects(:update_attributes).returns(false)
        put :update
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy' do
    before { FaGroup.stub(:find).and_return(@fa_group) }

    context 'successful destroy' do
      before do
        FaGroup.any_instance.expects(:update_attribute).returns(true)
        delete :destroy
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'FA Group deleted'
      end

      it 'redirects to action index' do
        response.should redirect_to(:action => 'index')
      end
    end

    context 'failed destroy' do
      before do
        FaGroup.any_instance.expects(:update_attribute).returns(false)
        delete :destroy
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Unable to delete FA Group.'
      end
    end
  end

  describe 'GET #assign_fa_groups' do
    before do
      @course = FactoryGirl.build(:course)
      Course.stub(:cce).and_return([@course])
      get :assign_fa_groups
    end

    it 'assigns @courses' do
      assigns(:courses).should == [@course]
    end

    it 'assigns @subjects' do
      assigns(:subjects).should == []
    end

    it 'renders the assign_fa_groups template' do
      response.should render_template('assign_fa_groups')
    end
  end

  describe 'GET #select_subjects' do
    before do
      @subject = FactoryGirl.build(:general_subject)
      Subject.stub(:find).and_return([@subject])
      get :select_subjects
    end

    it 'assigns @subjects' do
      assigns(:subjects).should  == [@subject]
    end

    it 'replaces element subjects with partial template' do
      response.should have_rjs(:replace_html, 'subjects')
      response.should render_template(:partial => 'subjects')
    end
  end

  describe 'POST #select_fa_groups' do
    before do
      @subject = FactoryGirl.build(:general_subject, :fa_groups => [@fa_group])
      Subject.stub(:find).and_return(@subject)
      FaGroup.stub(:active).and_return([@fa_group])
      post :select_fa_groups
    end

    it 'assigns @subject' do
      assigns(:subject).should == @subject
    end

    it 'assigns @subject_fa_groups' do
      assigns(:subject_fa_groups).should == [@fa_group]
    end

    it 'assigns @fa_groups' do
      assigns(:fa_groups).should == [@fa_group]
    end

    it 'replaces element flash-box' do
      response.should have_rjs(:replace_html, 'flash-box')
    end

    it 'replaces element select_fa_group with partial template' do
      response.should have_rjs(:replace_html, 'select_fa_group')
      response.should render_template(:partial => 'select_fa_group')
    end
  end

  describe 'PUT #update_subject_fa_groups' do
    before do
      @batch = FactoryGirl.build(:batch, :course_id => 1)
      @subject = FactoryGirl.build(:general_subject, :batch => @batch, :fa_groups => [@fa_group])
      Subject.stub(:find).and_return(@subject, [@subject])
      FaGroup.stub(:find_all_by_id).and_return([@fa_group])
    end

    context 'successful update' do
      before do
        Subject.any_instance.expects(:save).returns(true)
        put :update_subject_fa_groups
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'FA groups successfully assigned for the selected subject.'
      end

      it 'renders js' do
        response.body.should == "window.location='/fa_groups/assign_fa_groups'"
      end
    end

    context 'failed update' do
      before do
        Subject.any_instance.expects(:save).returns(false)
        FaGroup.stub(:active).and_return([@fa_group])
        put :update_subject_fa_groups
      end

      it 'assigns @error_object' do
        assigns(:error_object).should == @subject
      end

      it 'assigns @subject_fa_groups' do
        assigns(:subject_fa_groups).should == [@fa_group]
      end

      it 'assigns @fa_groups' do
        assigns(:fa_groups).should == [@fa_group]
      end

      it 'replaces element error-div with partial template' do
        response.should have_rjs(:replace_html, 'error-div')
        response.should render_template(:partial => 'layouts/_errors')
      end

      it 'replaces element select_fa_group with partial template' do
        response.should have_rjs(:replace_html, 'select_fa_group')
        response.should render_template(:partial => 'select_fa_group')
      end
    end
  end

  describe 'GET #new_fa_criteria' do
    before do
      FaGroup.stub(:find).and_return(@fa_group)
      get :new_fa_criteria
    end

    it 'assigns @fa_group' do
      assigns(:fa_group).should == @fa_group
    end

    it 'assigns @fa_criteria' do
      assigns(:fa_criteria).should be_new_record
    end

    it 'renders the new_fa_criteria template' do
      response.should render_template('new_fa_criteria')
    end
  end

  describe 'POST #create_fa_criteria' do
    before do
      FaCriteria.stub(:new).and_return(@fa_criteria)
      @fa_group.fa_criterias = [@fa_criteria]
      FaGroup.stub(:find).and_return(@fa_group)

    end

    context 'successful create' do
      before do
        FaCriteria.any_instance.expects(:save).returns(true)
        @fa_group.fa_criterias.stub(:active).and_return([@fa_criteria])
        post :create_fa_criteria, :fa_criteria => {}
      end

      it 'assigns @fa_group' do
        assigns(:fa_group).should == @fa_group
      end

      it 'assigns @fa_criterias' do
        assigns(:fa_criterias).should == [@fa_criteria]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'FA Criteria created successfully'
      end

      it 'renders the create_fa_criteria template' do
        response.should render_template('create_fa_criteria')
      end
    end

    context 'failed create' do
      before do
        FaCriteria.any_instance.expects(:save).returns(false)
        post :create_fa_criteria, :fa_criteria => {}
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #edit_fa_criteria' do
    before do
      FaCriteria.stub(:find).and_return(@fa_criteria)
      get :edit_fa_criteria
    end

    it 'assigns @fa_criteria' do
      assigns(:fa_criteria).should == @fa_criteria
    end

    it 'renders the edit_fa_criteria template' do
      response.should render_template('edit_fa_criteria')
    end
  end

  describe 'PUT #update_fa_criteria' do
    before { FaCriteria.stub(:find).and_return(@fa_criteria) }

    context 'successful update' do
      before do
        FaCriteria.any_instance.expects(:update_attributes).returns(true)
        @fa_criteria.fa_group.fa_criterias.stub(:active).and_return([@fa_criteria])
        put :update_fa_criteria
      end

      it 'assigns @fa_criterias' do
        assigns(:fa_criterias).should == [@fa_criteria]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'FA Criteria updated successfully'
      end

      it 'renders the update_fa_criteria template' do
        response.should render_template('update_fa_criteria')
      end
    end

    context 'failed update' do
      before do
        FaCriteria.any_instance.expects(:update_attributes).returns(false)
        put :update_fa_criteria
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy_fa_criteria' do
    before { FaCriteria.stub(:find).and_return(@fa_criteria) }

    context 'successful destroy' do
      before do
        FaCriteria.any_instance.expects(:update_attribute).returns(true)
        @fa_criteria.fa_group.fa_criterias.stub(:active).and_return([@fa_criteria])
        delete :destroy_fa_criteria
      end

      it 'assigns @fa_criteria' do
        assigns(:fa_criteria).should == @fa_criteria
      end

      it 'assigns @fa_group' do
        assigns(:fa_group).should == @fa_group
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'scholastic criteria deleted'
      end

      it 'assigns @fa_criterias' do
        assigns(:fa_criterias).should == [@fa_criteria]
      end

      it 'replaces element flash-box with text' do
        response.should have_rjs(:replace_html, 'flash-box')
        response.should include_text("<p class='flash-msg'>#{flash[:notice]}</p>")
      end

      it 'replaces element fa_criterias with partial template' do
        response.should have_rjs(:replace_html, 'fa_criterias')
        response.should render_template(:partial => 'fa_criterias')
      end
    end

    context 'successful destroy' do
      before do
        FaCriteria.any_instance.expects(:update_attribute).returns(false)
        delete :destroy_fa_criteria
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'scholastic criteria cannot be deleted'
      end
    end
  end

  describe 'POST #reorder' do
    before do
      @fa_criteria1 = FactoryGirl.build(:fa_criteria, :sort_order => 1, :fa_group => @fa_group)
      @fa_criteria2 = FactoryGirl.build(:fa_criteria, :sort_order => 2)
      FaCriteria.stub(:find).and_return(@fa_criteria1)
      @fa_group.fa_criterias = [@fa_criteria1, @fa_criteria2]
      @fa_group.fa_criterias.stub(:all).and_return([@fa_criteria1, @fa_criteria2])
      @fa_group.fa_criterias.stub(:active).and_return([@fa_criteria1, @fa_criteria2])
    end

    context 'params[:direction] == up' do
      before { post :reorder, :count => 1, :direction => 'up' }

      it 'assigns @fa_criterias' do
        assigns(:fa_criterias).should == [@fa_criteria1, @fa_criteria2]
      end

      it 'swaps sort_order of @fa_criteria1 and @fa_criteria2' do
        @fa_criteria1.sort_order.should == 2
        @fa_criteria2.sort_order.should == 1
      end

      it 'replaces element fa_criterias with partial template' do
        response.should have_rjs(:replace_html, 'fa_criterias')
        response.should render_template(:partial => 'fa_criterias')
      end
    end

    context 'params[:direction] == down' do
      before { post :reorder, :count => 0, :direction => 'down' }

      it 'swaps sort_order of @fa_criteria1 and @fa_criteria2' do
        @fa_criteria1.sort_order.should == 2
        @fa_criteria2.sort_order.should == 1
      end
    end
  end
end