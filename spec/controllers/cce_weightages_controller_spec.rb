require 'spec_helper'

describe CceWeightagesController do
  before do
    @course = FactoryGirl.build(:course)
    @cce_exam_category = FactoryGirl.build(:cce_exam_category)
    @cce_weightage = FactoryGirl.build(:cce_weightage)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      CceWeightage.stub(:all).and_return([@cce_weightage])
      get :index
    end

    it 'assigns @weightages' do
      assigns(:weightages).should == [@cce_weightage]
    end

    it 'renders the index template' do
      response.should render_template('index')
    end
  end

  describe 'GET #new' do
    before do
      CceExamCategory.stub(:all).and_return([@cce_exam_category])
      get :new
    end

    it 'assigns @criteria' do
      assigns(:criteria).should == ['FA', 'SA']
    end

    it 'assigns @exam_categories' do
      assigns(:exam_categories).should == [@cce_exam_category]
    end

    it 'assigns new record to @weightage' do
      assigns(:weightage).should be_new_record
    end

    it 'renders the new template' do
      response.should render_template('new')
    end
  end

  describe 'POST #create' do
    before { CceWeightage.stub(:new).with({ 'these' => 'params' }).and_return(@cce_weightage) }

    context 'successful create' do
      before do
        CceWeightage.any_instance.expects(:save).returns(true)
        CceWeightage.stub(:all).and_return([@cce_weightage])
        post :create, :cce_weightage => { 'these' => 'params' }
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Weightage created successfully.'
      end

      it 'assigns @weightages' do
        assigns(:weightages).should == [@cce_weightage]
      end

      it 'renders the create template' do
        response.should render_template('create')
      end
    end

    context 'failed create' do
      before do
        CceWeightage.any_instance.expects(:save).returns(false)
        post :create, :cce_weightage => { 'these' => 'params' }
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #show' do
    before do
      CceWeightage.stub(:find).and_return(@cce_weightage)
      @cce_weightage.courses = [@course]
      get :show
    end

    it 'assigns @weightage' do
      assigns(:weightage).should == @cce_weightage
    end

    it 'assigns @courses' do
      assigns(:courses).should == [@course]
    end

    it 'renders the show template' do
      response.should render_template('show')
    end
  end

  describe 'GET #edit' do
    before do
      CceWeightage.stub(:find).and_return(@cce_weightage)
      CceExamCategory.stub(:all).and_return([@cce_exam_category])
      get :edit
    end

    it 'assigns @weightage' do
      assigns(:weightage).should == @cce_weightage
    end

    it 'assigns @criteria' do
      assigns(:criteria).should == ['FA','SA']
    end

    it 'assigns @exam_categories' do
      assigns(:exam_categories).should == [@cce_exam_category]
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end
  end

  describe 'PUT #update' do
    before { CceWeightage.stub(:find).and_return(@cce_weightage) }

    context 'successful update' do
      before do
        CceWeightage.any_instance.expects(:update_attributes).returns(true)
        CceWeightage.stub(:all).and_return([@cce_weightage])
        put :update
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Weightage updated successfully.'
      end

      it 'assigns @weightages' do
        assigns(:weightages).should == [@cce_weightage]
      end

      it 'renders the update template' do
        response.should render_template('update')
      end
    end

    context 'successful update' do
      before do
        CceWeightage.any_instance.expects(:update_attributes).returns(false)
        put :update
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy' do
    before { CceWeightage.stub(:find).and_return(@cce_weightage) }

    it 'redirects to action index' do
      delete :destroy
      response.should redirect_to(:action => 'index')
    end

    context '@weightage.courses is empty' do
      before { @cce_weightage.courses = [] }

      context 'successful destroy' do
        before { CceWeightage.any_instance.expects(:destroy).returns(true) }

        it 'assigns flash[:notice]' do
          delete :destroy
          flash[:notice].should == 'Weightage deleted.'
        end
      end

      context 'failed destroy' do
        before { CceWeightage.any_instance.expects(:destroy).returns(false) }

        it 'assigns flash[:warn_notice]' do
          delete :destroy
          flash[:warn_notice].should == 'Weightage could be deleted.'
        end
      end
    end

    context '@weightage.courses is any' do
      before { @cce_weightage.courses = [@course] }

      it 'assigns flash[:warn_notice]' do
        delete :destroy
        flash[:warn_notice].should == "CCE weightage #{@cce_weightage.weightage}(#{@cce_weightage.criteria_type}) has been assigned to courses. Remove the associations before deleting."
      end
    end
  end

  describe 'POST #assign_courses' do
    before do
      CceWeightage.stub(:find).and_return(@cce_weightage)
      Course.stub(:active).and_return([@course])
      Course.stub(:find_all_by_id).with([1,2,3]).and_return([@course])
      post :assign_courses, :cce_weightage => {:course_ids => [1,2,3]}
    end

    it 'assigns @weightage' do
      assigns(:weightage).should == @cce_weightage
    end

    it 'assigns @courses' do
      assigns(:courses).should == [@course]
    end

    it 'assigns @weightage.courses' do
      assigns(:weightage).courses.should == [@course]
    end

    it 'assigns flash[:notice]' do
      flash[:notice].should == 'saved'
    end

    it 'redirects to' do
      response.should redirect_to('')
    end
  end

  describe 'GET #assign_weightages' do
    before do
      Course.stub(:cce).and_return([@course])
      get :assign_weightages
    end

    it 'assigns @courses' do
      assigns(:courses).should == [@course]
    end

    it 'renders the assign_weightages template' do
      response.should render_template('assign_weightages')
    end
  end

  describe 'POST #select_weightages' do
    before do
      Course.stub(:find).and_return(@course)
      @observation_group = FactoryGirl.build(:observation_group)
      @course.observation_groups = [@observation_group]
      CceWeightage.stub(:all).and_return([@cce_weightage])
      post :select_weightages
    end

    it 'assigns @course' do
      assigns(:course).should == @course
    end

    it 'assigns @course_weightages' do
      assigns(:course_weightages).should == [@observation_group]
    end

    it 'assigns @weightages' do
      assigns(:weightages).should == [@cce_weightage]
    end

    it 'replaces element flash-box' do
      response.should have_rjs(:replace_html, 'flash-box')
    end

    it 'replaces element error-div' do
      response.should have_rjs(:replace_html, 'error-div')
    end

    it 'replaces element select_weightages with partial template' do
      response.should have_rjs(:replace_html, 'select_weightages')
      response.should render_template(:partial => 'select_weightage')
    end
  end

  describe 'POST #update_course_weightages' do
    before do
      Course.stub(:find).and_return(@course)
      CceWeightage.stub(:find_all_by_id).with([1,2,3]).and_return([@cce_weightage])
      CceWeightage.stub(:all).and_return([@cce_weightage])
    end

    context 'successful update' do
      before do
        Course.any_instance.expects(:save).returns(true)
        post :update_course_weightages, :course => {:weightage_ids => [1,2,3]}
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'CCE weightages for the couse assigned successfully.'
      end

      it 'renders js' do
        response.body.should == "window.location='/cce_weightages/assign_weightages'"
      end
    end

    context 'failed update' do
      before do
        Course.any_instance.expects(:save).returns(false)
        post :update_course_weightages, :course => {:weightage_ids => [1,2,3]}
      end

      it 'assigns @error_object' do
        assigns(:error_object).should == @course
      end

      it 'replaces element error-div with partial template' do
        response.should have_rjs(:replace_html, 'error-div')
        response.should render_template(:partial => 'layouts/_errors')
      end

      it 'replaces element select_weightages-div with partial template' do
        response.should have_rjs(:replace_html, 'select_weightages')
        response.should render_template(:partial => 'select_weightage')
      end
    end
  end
end