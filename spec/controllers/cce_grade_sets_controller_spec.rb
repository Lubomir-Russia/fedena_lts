require 'spec_helper'

describe CceGradeSetsController do
  before do
    @cce_grade_set = FactoryGirl.build(:cce_grade_set)
    @cce_grade = FactoryGirl.build(:cce_grade, :cce_grade_set => @cce_grade_set)
    @user = Factory.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      CceGradeSet.stub(:all).and_return([@cce_grade_set])
      get :index
    end

    it 'renders the index template' do
      response.should render_template('index')
    end

    it 'assigns all CceGradeSet as @grade_sets' do
      assigns(:grade_sets).should == [@cce_grade_set]
    end
  end

  describe 'GET #new' do
    before do
      get :new
    end

    it 'renders the new template' do
      response.should render_template('new')
    end

    it 'assigns new record to @grade_set' do
      assigns(:grade_set).should be_new_record
    end
  end

  describe 'POST #create' do
    before do
      CceGradeSet.stub(:new).with({ 'these' => 'params' }).and_return(@cce_grade_set)
    end

    context 'successful create' do
      before do
        CceGradeSet.any_instance.expects(:save).returns(true)
        CceGradeSet.stub(:all).and_return([@cce_grade_set])
        post :create, :cce_grade_set => { 'these' => 'params' }
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "CCE Gradeset created successfully."
      end

      it 'assigns all CceGradeSet as @grade_sets' do
        assigns(:grade_sets).should == [@cce_grade_set]
      end
    end

    context 'failed create' do
      before do
        CceGradeSet.any_instance.expects(:save).returns(false)
        post :create, :cce_grade_set => { 'these' => 'params' }
      end

      it 'assigns @error is true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #edit' do
    before do
      CceGradeSet.stub(:find).and_return(@cce_grade_set)
      get :edit, :id => 2
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end

    it 'assigns @grade_set' do
      assigns(:grade_set).should == @cce_grade_set
    end
  end

  describe 'PUT #update' do
    context 'successful update' do
      before do
        CceGradeSet.stub(:find).and_return(@cce_grade_set)
        CceGradeSet.stub(:all).and_return([@cce_grade_set])
        CceGradeSet.any_instance.expects(:save).returns(true)
        put :update, :id => 2, :cce_grade_set => { :name => 'CCE Name' }
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "CCE Gradeset updated successfully."
      end

      it 'assigns @grade_sets' do
        assigns(:grade_sets).should == [@cce_grade_set]
      end
    end

    context 'failed update' do
      before do
        CceGradeSet.stub(:find).and_return(@cce_grade_set)
        CceGradeSet.any_instance.expects(:save).returns(false)
        put :update, :id => 2, :cce_grade_set => { :name => 'CCE Name' }
      end

      it 'assigns @error is true' do
        assigns(:error).should be_true
      end

    end
  end

  describe 'GET #show' do
    before do
      @cce_grade_set.cce_grades = [@cce_grade]
      CceGradeSet.stub(:find).and_return(@cce_grade_set)
      get :show, :id => 2
    end

    it 'renders the edit template' do
      response.should render_template('show')
    end

    it 'assigns @grades' do
      assigns(:grades).should == [@cce_grade]
    end
  end

  describe 'DELETE #destroy' do
    before { CceGradeSet.stub(:find).and_return(@cce_grade_set) }

    context '@grade_set.observation_groups is empty' do
      before do
        @cce_grade_set.observation_groups = []
        CceGradeSet.any_instance.expects(:destroy).returns(true)
        delete :destroy, :id => 2
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "Grade set deleted."
      end

      it 'redirects to the action index' do
        response.should redirect_to(:action => 'index')
      end
    end

    context '@grade_set.observation_groups is any' do
      before do
        @observation_group = FactoryGirl.build(:observation_group)
        @cce_grade_set.observation_groups = [@observation_group]
        delete :destroy, :id => 2
      end

      it 'assigns flash[:warn_notice]' do
        flash[:warn_notice].should == "Grade set #{@cce_grade_set.name} is associated to some Co-Scholastic groups. Clear them before deleting."
      end
    end
  end

  describe 'GET #new_grade' do
    before do
      CceGradeSet.stub(:find).and_return(@cce_grade_set)
      get :new_grade, :id => 2, :format => 'js'
    end

    it 'renders the new_grade template' do
      response.should render_template('new_grade')
    end

    it 'assigns @grade_set' do
      assigns(:grade_set).should == @cce_grade_set
    end

    it 'assigns new record to @grade' do
      assigns(:grade).should be_new_record
    end
  end

  describe 'POST #create_grade' do
    before do
      CceGrade.stub(:new).with({ 'these' => 'params' }).and_return(@cce_grade)
    end

    context 'successful create' do
      before do
        CceGrade.any_instance.expects(:save).returns(true)
        @cce_grade_set.cce_grades = [@cce_grade]
        post :create_grade, :cce_grade => { 'these' => 'params' }
      end

      it 'assigns @grades' do
        assigns(:grades).should == [@cce_grade]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "Grade created successfully"
      end
    end

    context 'failed create' do
      before do
        CceGrade.any_instance.expects(:save).returns(false)
        post :create_grade, :cce_grade => { 'these' => 'params' }
      end

      it 'assigns @error is true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #edit_grade' do
    before do
      CceGrade.stub(:find).and_return(@cce_grade)
      get :edit_grade, :id => 2, :format => 'js'
    end

    it 'assigns @grade' do
      assigns(:grade).should == @cce_grade
    end

    it 'renders the edit_grade template' do
      response.should render_template('edit_grade')
    end
  end

  describe 'PUT #update_grade' do
    before do
      CceGrade.stub(:find).and_return(@cce_grade)
    end

    context 'successful update' do
      before do
        CceGrade.any_instance.expects(:update_attributes).with({ 'these' => 'params' }).returns(true)
        @cce_grade_set.cce_grades = [@cce_grade]
        put :update_grade, :id => 2, :grade => { 'these' => 'params' }
      end

      it 'assigns @grades' do
        assigns(:grades).should == [@cce_grade]
      end
    end

    context 'failed update' do
      before do
        CceGrade.any_instance.expects(:update_attributes).with({ 'these' => 'params' }).returns(false)
        put :update_grade, :id => 2, :grade => { 'these' => 'params' }
      end

      it 'assigns @error is true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy_grade' do
    before do
      @cce_grade_set.cce_grades = [@cce_grade]
      CceGrade.stub(:find).and_return(@cce_grade)

    end

    context 'successful destroy' do
      before do
        @cce_grade.stub(:destroy).and_return(true)
        delete :destroy_grade, :id => 2
      end

      it 'assigns @grades' do
        assigns(:grades).should == [@cce_grade]
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "Grade deleted."
      end

      it 'renders the grades template' do
        response.should render_template('grades')
      end
    end

    context 'failed destroy' do
      before do
        @cce_grade.stub(:destroy).and_return(false)
        delete :destroy_grade, :id => 2
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "Could not delete grade."
      end
    end

  end
end