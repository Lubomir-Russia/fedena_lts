require 'spec_helper'

describe DescriptiveIndicatorsController do
  before do
    @observation = FactoryGirl.build(:observation)
    @observation_group = FactoryGirl.build(:observation_group)
    @fa_criteria = FactoryGirl.build(:fa_criteria)
    @fa_group = FactoryGirl.build(:fa_group)
    @descriptive_indicator = FactoryGirl.build(:descriptive_indicator, :describable => @observation, :sort_order => 1)
    @user = FactoryGirl.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #new' do
    context 'param observation_id is present' do
      before do
        Observation.stub(:find).and_return(@observation)
        get :new, :observation_id => 1
      end

      it 'assigns @observation' do
        assigns(:observation).should == @observation
      end

      it 'assigns @descriptive' do
        assigns(:descriptive).should be_new_record
      end

      it 'renders the new template' do
        response.should render_template('new')
      end
    end

    context 'param fa_criteria_id is present' do
      before do
        FaCriteria.stub(:find).and_return(@fa_criteria)
        get :new, :fa_criteria_id => 1
      end

      it 'assigns @fa_criteria' do
        assigns(:fa_criteria).should == @fa_criteria
      end

      it 'assigns @descriptive' do
        assigns(:descriptive).should be_new_record
      end
    end
  end

  describe 'POST #create' do
    context 'params[:observation_id] is present' do
      before do
        Observation.stub(:find).and_return(@observation)
        @observation.descriptive_indicators.stub(:new).with({ 'these' => 'params' }).and_return(@descriptive_indicator)
      end

      context 'successful create' do
        before do
          DescriptiveIndicator.any_instance.expects(:save).returns(true)
          @descriptive_indicator.describable.descriptive_indicators.stub(:all).and_return([@descriptive_indicator])
          post :create, :observation_id => 2, :descriptive_indicator => { 'these' => 'params' }
        end

        it 'assigns @describable' do
          assigns(:describable).should == @observation
        end

        it 'assigns @observation' do
          assigns(:observation).should == @descriptive_indicator
        end

        it 'assigns @descriptive_indicators' do
          assigns(:descriptive_indicators).should == [@descriptive_indicator]
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == 'Descriptive Indicator Created Successfully.'
        end

        it 'renders the create template' do
          response.should render_template('create')
        end
      end

      context 'failed create' do
        before do
          DescriptiveIndicator.any_instance.expects(:save).returns(false)
          post :create, :observation_id => 2, :descriptive_indicator => { 'these' => 'params' }
        end

        it 'assigns @observation' do
          assigns(:observation).should == @observation
        end

        it 'assigns @error to true' do
          assigns(:error).should be_true
        end
      end
    end

    context 'params[:fa_criteria_id] is present' do
      before do
        FaCriteria.stub(:find).and_return(@fa_criteria)
        @fa_criteria.descriptive_indicators.stub(:new).with({ 'these' => 'params' }).and_return(@descriptive_indicator)
      end

      context 'successful create' do
        before do
          DescriptiveIndicator.any_instance.expects(:save).returns(true)
          @descriptive_indicator.describable.descriptive_indicators.stub(:all).and_return([@descriptive_indicator])
          post :create, :fa_criteria_id => 2, :descriptive_indicator => { 'these' => 'params' }
        end

        it 'assigns @fa_criteria' do
          assigns(:fa_criteria).should == @descriptive_indicator
        end
      end

      context 'failed create' do
        before do
          DescriptiveIndicator.any_instance.expects(:save).returns(false)
          post :create, :fa_criteria_id => 2, :descriptive_indicator => { 'these' => 'params' }
        end

        it 'assigns @fa_criteria' do
          assigns(:fa_criteria).should == @fa_criteria
        end
      end
    end
  end

  describe 'GET #index' do
    context 'params[:observation_id] is present' do
      before do
        Observation.stub(:find).and_return(@observation)
        @observation.descriptive_indicators.stub(:all).and_return([@descriptive_indicator])
        @observation.observation_group = @observation_group
        get :index, :observation_id => 2
      end

      it 'assigns @observation' do
        assigns(:observation).should == @observation
      end

      it 'assigns @descriptive_indicators' do
        assigns(:descriptive_indicators).should == [@descriptive_indicator]
      end

      it 'assigns @observation_group' do
        assigns(:observation_group).should == @observation_group
      end

      it 'renders the index template' do
        response.should render_template('index')
      end
    end

    context 'params[:fa_criteria_id] is present' do
      before do
        FaCriteria.stub(:find).and_return(@fa_criteria)
        @fa_criteria.descriptive_indicators.stub(:all).and_return([@descriptive_indicator])
        @fa_criteria.fa_group = @fa_group
        get :index, :fa_criteria_id => 2
      end

      it 'assigns @fa_criteria' do
        assigns(:fa_criteria).should == @fa_criteria
      end

      it 'assigns @descriptive_indicators' do
        assigns(:descriptive_indicators).should == [@descriptive_indicator]
      end

      it 'assigns @fa_group' do
        assigns(:fa_group).should == @fa_group
      end
    end
  end

  describe 'GET #edit' do
    before do
      DescriptiveIndicator.stub(:find).and_return(@descriptive_indicator)
      get :edit
    end

    it 'assigns @descriptive' do
      assigns(:descriptive).should == @descriptive_indicator
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end
  end

  describe 'PUT #update' do
    before { DescriptiveIndicator.stub(:find).and_return(@descriptive_indicator) }

    context 'successful update' do
      before do
        DescriptiveIndicator.any_instance.expects(:update_attributes).returns(true)
        @descriptive_indicator.describable.descriptive_indicators.stub(:all).and_return([@descriptive_indicator])
      end

      context '@descriptive_indicator.describable_type = Observation' do
        before do
          @descriptive_indicator.describable_type = 'Observation'
          put :update
        end

        it 'assigns @descriptive_indicators' do
          assigns(:descriptive_indicators).should == [@descriptive_indicator]
        end

        it 'assigns @observation' do
          assigns(:observation).should == @descriptive_indicator
        end

        it 'assigns flash[:notice]' do
          flash[:notice].should == 'Descriptive Indicator Updated Successfully.'
        end

        it 'renders the update template' do
          response.should render_template('update')
        end
      end

      context '@descriptive_indicator.describable_type = FaCriteria' do
        before do
          @descriptive_indicator.describable_type = 'FaCriteria'
          put :update
        end

        it 'assigns @fa_criteria' do
          assigns(:fa_criteria).should == @descriptive_indicator
        end
      end
    end

    context 'failed update' do
      before do
        DescriptiveIndicator.any_instance.expects(:update_attributes).returns(false)
        put :update
      end

      it 'assigns @error to true' do
        assigns(:error).should be_true
      end
    end
  end

  describe 'DELETE #destroy_indicator' do
    before { DescriptiveIndicator.stub(:find).and_return(@descriptive_indicator) }

    context 'successful destroy' do
      before do
        DescriptiveIndicator.any_instance.expects(:destroy).returns(true)
        @descriptive_indicator.describable.descriptive_indicators.stub(:all).with(:order => 'sort_order ASC').and_return([@descriptive_indicator])
        delete :destroy_indicator
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Descriptive indicator deleted.'
      end

      it 'assigns @descriptive_indicators' do
        assigns(:descriptive_indicators).should == [@descriptive_indicator]
      end

      it 'replaces element flash-box with text' do
        response.should have_rjs(:replace_html, 'flash-box')
        response.should include_text("<p class='flash-msg'>#{flash[:notice]}</p>")
      end

      it 'replaces element descriptive_indicators with partial template' do
        response.should have_rjs(:replace_html, 'descriptive_indicators')
        response.should render_template(:partial => 'descriptive_indicators')
      end
    end

    context 'failed destroy' do
      before do
        DescriptiveIndicator.any_instance.expects(:destroy).returns(false)
        @descriptive_indicator.describable.descriptive_indicators.stub(:all).with(:order => 'sort_order ASC').and_return([@descriptive_indicator])
        delete :destroy_indicator
      end

      it 'assigns flash[:notice]' do
        flash[:notice].should == 'Unable to delete the descriptive indicator'
      end
    end
  end

  describe 'POST #reorder' do
    let(:descriptive_indicator1) { FactoryGirl.build(:descriptive_indicator, :sort_order => 1) }
    let(:descriptive_indicator2) { FactoryGirl.build(:descriptive_indicator, :sort_order => 2) }

    before do
      DescriptiveIndicator.stub(:find).and_return(descriptive_indicator1)
      descriptive_indicator1.stub(:describable).and_return(@observation)
      @observation.descriptive_indicators.stub(:all).and_return([descriptive_indicator1, descriptive_indicator2])
    end

    context 'params[:direction] == up' do
      before { post :reorder, :count => 1, :direction => 'up' }

      it 'assigns @descriptive_indicators' do
        assigns(:descriptive_indicators).should == [descriptive_indicator1, descriptive_indicator2]
      end

      it 'swaps sort_order of descriptive_indicator1 and descriptive_indicator2' do
        descriptive_indicator1.sort_order.should == 2
        descriptive_indicator2.sort_order.should == 1
      end

      it 'replaces element descriptive_indicators with partial template' do
        response.should have_rjs(:replace_html, 'descriptive_indicators')
        response.should render_template(:partial => 'descriptive_indicators')
      end
    end

    context 'params[:direction] == down' do
      before { post :reorder, :count => 0, :direction => 'down' }

      it 'assigns @descriptive_indicators' do
        assigns(:descriptive_indicators).should == [descriptive_indicator1, descriptive_indicator2]
      end

      it 'swaps sort_order of descriptive_indicator1 and descriptive_indicator2' do
        descriptive_indicator1.sort_order.should == 2
        descriptive_indicator2.sort_order.should == 1
      end
    end
  end
end