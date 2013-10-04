require 'spec_helper'

describe ClassDesignationsController do
  before do

    @class_designation = FactoryGirl.build(:class_designation)
    @course = FactoryGirl.build(:course, :class_designations => [@class_designation])
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #load_class_designations' do
    context 'param course_id is present' do
      before do
        Course.stub(:find).and_return(@course)
        ClassDesignation.stub(:find_all_by_course_id).and_return([@class_designation])
        get :load_class_designations, :course_id => 1
      end

      it 'assigns @class_designations' do
        assigns(:class_designations).should == [@class_designation]
      end

      it 'assigns new record to @class_designation' do
        assigns(:class_designation).should be_new_record
      end

      it 'renders the course_class_designations template' do
        response.should render_template('course_class_designations')
      end

      it 'replaces element course_class_designations' do
        response.should have_rjs(:replace_html, 'course_class_designations')
      end

      it 'replaces element flash' do
        response.should have_rjs(:replace_html, 'flash')
      end
    end

    context 'param course_id is nil' do
      before do
        get :load_class_designations
      end

      it 'replaces element course_class_designations' do
        response.should have_rjs(:replace_html, 'course_class_designations')
      end

      it 'replaces element flash' do
        response.should have_rjs(:replace_html, 'flash')
      end
    end
  end

  describe 'POST #create_class_designation' do
    before do
      Course.stub(:find).and_return(@course)
      ClassDesignation.stub(:new).and_return(@class_designation)
    end

    context 'successful create' do
      before do
        ClassDesignation.any_instance.expects(:save).returns(true)
        @course.class_designations.stub(:all).and_return([@class_designation])
        post :create_class_designation
      end

      it 'assigns @course' do
        assigns(:course).should == @course
      end

      it 'assigns @class_designations' do
        assigns(:class_designations).should == [@class_designation]
      end

      it 'assigns new record to @class_designation' do
        assigns(:class_designation).should be_new_record
      end

      it 'replaces element category-list with partial template' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'class_designations')
      end

      it 'replaces element flash with text' do
        response.should have_rjs(:replace_html, 'flash')
        response.should include_text("<p class='flash-msg'>#{I18n.t('class_designations.flash1')}</p>")
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element class_form with partial template' do
        response.should have_rjs(:replace_html, 'class_form')
        response.should render_template(:partial => 'class_form')
      end
    end

    context 'failed create' do
      before do
        ClassDesignation.any_instance.expects(:save).returns(false)
        post :create_class_designation
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

  describe 'GET #edit_class_designation' do
    before do
      ClassDesignation.stub(:find).and_return(@class_designation)
      @class_designation.course = @course
      get :edit_class_designation
    end

    it 'replaces element flash' do
      response.should have_rjs(:replace_html, 'flash')
    end

    it 'replaces element errors with partial template' do
      response.should have_rjs(:replace_html, 'errors')
      response.should render_template(:partial => 'form_errors')
    end

    it 'replaces element class_form with partial template' do
      response.should have_rjs(:replace_html, 'class_form')
      response.should render_template(:partial => 'class_edit_form')
    end
  end

  describe 'PUT #update_class_designation' do
    before do
      ClassDesignation.stub(:find).and_return(@class_designation)
      @class_designation.course = @course

    end

    context 'successful update' do
      before do
        ClassDesignation.any_instance.expects(:update_attributes).returns(true)
        @course.class_designations.stub(:all).and_return([@class_designation])
        put :update_class_designation
      end

      it 'assigns @course' do
        assigns(:course).should == @course
      end

      it 'assigns new record to @class_designation' do
        assigns(:class_designation).should be_new_record
      end

      it 'assigns @class_designations' do
        assigns(:class_designations).should == [@class_designation]
      end

      it 'replaces element category-list with partial template' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'class_designations')
      end

      it 'replaces element flash with text' do
        response.should have_rjs(:replace_html, 'flash')
        response.should include_text("<p class='flash-msg'> #{I18n.t('class_designations.flash2')}</p>")
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element class_form with partial template' do
        response.should have_rjs(:replace_html, 'class_form')
        response.should render_template(:partial => 'class_form')
      end
    end

    context 'failed update' do
      before do
        ClassDesignation.any_instance.expects(:update_attributes).returns(false)
        put :update_class_designation
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

  describe 'DELETE #delete_class_designation' do
    before do
      ClassDesignation.stub(:find).and_return(@class_designation)
      @class_designation.course = @course
      @course.class_designations.stub(:all).and_return([@class_designation])
    end

    it 'calls class_designation destroy' do
      @class_designation.should_receive(:destroy)
      delete :delete_class_designation
    end

    context 'destroy @class_designation' do
      before { delete :delete_class_designation }

      it 'assigns @course' do
        assigns(:course).should == @course
      end

      it 'assigns @class_designation' do
        assigns(:class_designation).should be_new_record
      end

      it 'assigns @class_designations' do
        assigns(:class_designations).should == [@class_designation]
      end

      it 'replaces element category-list with partial template' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'class_designations')
      end

      it 'replaces element flash with text' do
        response.should have_rjs(:replace_html, 'flash')
        response.should include_text("<p class='flash-msg'>#{I18n.t('class_designations.flash3')}</p>")
      end

      it 'replaces element errors with partial template' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'form_errors')
      end

      it 'replaces element class_form with partial template' do
        response.should have_rjs(:replace_html, 'class_form')
        response.should render_template(:partial => 'class_form')
      end
    end
  end
end