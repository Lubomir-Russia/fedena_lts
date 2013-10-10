require 'spec_helper'

describe ObservationGroupsController do
  before do
    @user = Factory.create(:admin_user)
    @obs_group = FactoryGirl.create(:observation_group)
    
    sign_in(@user)
  end

  describe 'GET #index' do
    context 'params[:query] is nil' do
      before do
        FactoryGirl.create(:observation_group, :is_deleted => true)
        get :index
      end

      it 'renders the index template' do
        response.should render_template('index')
      end

      it 'assigns @obs_groups' do
        assigns(:obs_groups).should == [@obs_group]
      end
    end
  end

  describe 'GET #new' do
    before { get :new }

    it 'renders the index template' do
      response.should render_template('new')
    end

    it 'assigns @obs_groups' do
      assigns(:obs_group).should be_kind_of(ObservationGroup)
    end
  end

  describe 'POST #create' do
    before do
      @obs_group = ObservationGroup.new()
      ObservationGroup.stub(:new).with({ 'these' => 'params' }).and_return(@obs_group)
    end

    context 'successful create' do
      before do
        ObservationGroup.any_instance.expects(:save).returns(true)
        post :create, :observation_group => { 'these' => 'params' }
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == "Co-Scholastic Group Created Successfully."
      end
    end

    context 'failed create' do
      before do
        ObservationGroup.any_instance.expects(:save).returns(false)
        post :create, :observation_group => { 'these' => 'params' }
      end

      it 'assigns @error' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #show' do
    context 'ObservationGroup is found' do
      let!(:observation) { create(:observation, observation_group: @obs_group) }
      before { get :show, :id => @obs_group }

      it 'renders the show template' do
        response.should render_template('show')
      end

      it 'assigns @obs_group and @observations' do
        assigns(:obs_group).should == @obs_group
        assigns(:observations).should == [observation]
      end
    end

    context 'ObservationGroup is not found' do
      it 'returns error' do
        expect { get :show, :id => '17853981023' }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'GET #edit' do
    before do
      @grade_sets = CceGradeSet.all
      @observation_kinds = ObservationGroup::OBSERVATION_KINDS
      get :edit, :id => @obs_group
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end

    it 'assigns @obs_group and @observations' do
      assigns(:obs_group).should == @obs_group
      assigns(:grade_sets).should == @grade_sets
      assigns(:observation_kinds).should == @observation_kinds
    end
  end

  describe 'PUT #update' do
    context 'valid attributes' do
      before { put :update, :id => @obs_group, :observation_group => { :name => 'Name1' } }

      it 'changes @obs_group' do
        @obs_group.reload
        @obs_group.name.should == 'Name1'
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Co-Scholastic Group Updated Successfully.'
      end
    end

    context 'invalid attributes' do
      before { put :update, :id => @obs_group, :observation_group => { :name => nil } }
      
      it 'does not change @obs_group' do 
        @obs_group.reload
        @obs_group.name.should_not be_nil
      end

      it 'assigns @error' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, :id => @obs_group }
    
    it 'assigns flash[:notice]' do
      flash[:notice].should == 'Co-Scholastic Group Deleted.'
    end

    it 'redirects to the observation_groups_path' do
      response.should redirect_to(observation_groups_path)
    end
  end

  describe 'GET #new_observation' do
    before { get :new_observation, :id => @obs_group }
    
    it 'assigns @obs_group' do
      assigns(:obs_group).should == @obs_group
      assigns(:observation).should be_new_record
    end
  end

  describe 'POST #create_observation' do
    context 'valid attributes' do
      it 'created a new observation' do
        expect {
          post :create_observation, :observation => { :name => 'N', :desc => 'D', :observation_group_id => @obs_group.id }
        }.to change(Observation, :count).by(1)
      end

      it 'assigns flash[:notice]' do
        post :create_observation, :observation => { :name => 'N', :desc => 'D', :observation_group_id => @obs_group.id }
        flash[:notice].should == 'Co-Scholastic Criteria Created Successfully.'
      end
    end

    context 'invalid attributes' do
      it 'does not create a new observation' do
        expect {
          post :create_observation, :observation => { :name => nil, :desc => 'D', :observation_group_id => @obs_group.id }
        }.to_not change(Observation, :count)
      end

      it 'assigns @error' do
        post :create_observation, :observation => { :name => nil, :desc => 'D', :observation_group_id => @obs_group.id }
        assigns(:error).should be_true
      end
    end
  end

  describe 'GET #edit_observation' do
    before do
      @observation = create(:observation, :observation_group => @obs_group)
      post :edit_observation, :id => @observation
    end

    it 'assigns @obs_group and @observations' do
      assigns(:obs_group).should == @obs_group
      assigns(:observation).should == @observation
    end
  end

  describe 'PUT #update_observation' do
    let!(:observation) { create(:observation, :observation_group => @obs_group) }
    
    context 'valid attributes' do
      before { put :update_observation, :id => observation, :observation => { :name => 'N', :observation_group_id => @obs_group.id } }

      it 'changes @observation' do
        observation.reload
        observation.name.should == 'N'
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Co-Scholastic Criteria updated Successfully.'
      end
    end

    context 'invalid attributes' do
      before { put :update_observation, :id => observation, :observation => { :name => nil, :observation_group_id => @obs_group.id } }
      
      it 'does not change @obs_group' do 
        @obs_group.reload
        @obs_group.name.should_not be_nil
      end

      it 'assigns @error' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'POST #select_observation_groups' do
    context 'course is found' do
      let(:course) { create(:course) }
      before { course.observation_groups << @obs_group }

      it 'assigns information' do
        post :select_observation_groups, :course_id => course.id
        assigns[:course].should == course
        assigns[:obs_groups].should == [@obs_group]
      end

      it 'renders update' do
        page = mock('Page')
        controller.expects(:render).yields(page).at_least_once
        page.expects(:replace_html).times(2)
        post :select_observation_groups, :course_id => course.id
      end
    end

    context 'course is not found' do
      it 'returns error' do
        expect { post :select_observation_groups, :course_id => nil }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

   describe 'PUT #update_course_obs_groups' do
    context 'course is found' do
      let(:course) { create(:course) }

      context 'params course is not nil' do
        before { put :update_course_obs_groups, :id => course.id, :course => { :observation_group_ids => @obs_group.id } }

        it 'assigns information' do
          assigns[:course].should == course
          assigns[:course_observation_groups].should == [@obs_group]
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == 'Co-Scholastic groups successfully assigned to the selected course.'
        end

        it 'renders assign_courses' do
          response.body.should == "window.location='/observation_groups/assign_courses'"
        end
      end

      context 'params course is nil' do
        before { put :update_course_obs_groups, :id => course.id }

        it 'assigns informations' do
          assigns[:course].should == course
          assigns[:course_observation_groups].should == []
        end
      end
    end

    context 'course is not found' do
      it 'returns error' do
        expect { put :update_course_obs_groups, :id => nil }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'POST #destroy_observation' do
    context 'observation is found' do
      let(:observation) { create(:observation, 
        :observation_group => @obs_group,
        :is_active => true) }
      before { post :destroy_observation, :id => observation }

      it 'assigns informations' do
        assigns[:observation].should == observation
        assigns[:obs_group].should == @obs_group
      end

      it 'updates @observation' do
        observation.reload
        observation.is_active.should be_false
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Co-scholastic criteria deleted.'
      end

      it 'renders update' do
        page = mock('Page')
        controller.expects(:render).yields(page).at_least_once
        page.expects(:replace_html).times(2)
        post :destroy_observation, :id => observation
      end
    end

    context 'observation is not found' do
      it 'returns error' do
        expect { post :destroy_observation, :id => nil }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'POST #reorder' do
    let!(:observation1) { create(:observation, :observation_group => @obs_group, :sort_order => 1) }
    let!(:observation2) { create(:observation, :observation_group => @obs_group, :sort_order => 2) }

    context 'request is POST' do
      it 'reorder observation up' do
        post :reorder, :id => observation1, :count => '1', :direction => 'up'
        assigns[:observations].should == [observation2, observation1]
      end

      it 'reorder observation down' do
        post :reorder, :id => observation1, :count => '0', :direction => 'down'
        assigns[:observations].should == [observation2, observation1]
      end

      it 'renders update' do
        page = mock('Page')
        controller.expects(:render).yields(page).at_least_once
        page.expects(:replace_html).times(1)
        post :reorder, :id => observation1, :count => '0', :direction => 'down'
      end
    end

    context 'request is not POST' do
      it 'returns nil' do
        get :reorder, :id => observation1, :count => '0', :direction => 'down'
        assigns[:observations].should be_nil
      end
      
      it 'does not renders update' do
        page = mock('Page')
        page.expects(:replace_html).times(0)
        get :reorder, :id => observation1, :count => '0', :direction => 'down'
      end
    end
  end

end
