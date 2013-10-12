require 'spec_helper'

describe RankingLevelsController do
  before do
    @user = Factory.create(:admin_user)
    @course = FactoryGirl.create(:course)
    @ranking_level = FactoryGirl.create(:ranking_level, :course => @course)

    sign_in(@user)
  end

  describe 'GET #load_ranking_levels' do
    context 'course_id is not nil' do
      before { get :load_ranking_levels, :course_id => @course }

      it 'assigns informations' do
        assigns(:course).should == @course
        assigns(:ranking_levels).should == [@ranking_level]
        assigns(:ranking_level).should be_new_record
      end

      it 'replaces partial template' do
        response.should have_rjs(:replace_html, 'course_ranking_levels')
        response.should render_template(:partial => 'course_ranking_levels')
      end
    end

    context 'course_id is nil' do
      before { get :load_ranking_levels, :course_id => nil }

      it 'assigns informations' do
        assigns(:course).should be_nil
        assigns(:ranking_levels).should be_nil
        assigns(:ranking_level).should be_nil
      end

      it 'replaces partial template' do
        response.should have_rjs(:replace_html, 'course_ranking_levels')
      end
    end
  end

  describe 'POST #create_ranking_level' do
    context 'valid attributes' do
      it 'creates ranking_level' do
        expect { post :create_ranking_level, :course_id => @course, :ranking_level => { :name => 'rank1', :marks => '10'} }.to change(RankingLevel, :count).by(1)
      end

      it 'replaces template with informations' do
        post :create_ranking_level, :course_id => @course.id, :ranking_level => { :name => 'rank1', :marks => '12', :full_course => '0' }
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'ranking_levels')
        response.should render_template(:partial => 'rank_errors')
        response.should render_template(:partial => 'rank_form')
      end
    end

    context 'invalid attributes' do
      it 'does not create ranking_level' do
        expect { post :create_ranking_level, :course_id => @course, :ranking_level => { :name => 'rank1'} }.to change(RankingLevel, :count).by(0)
      end

      it 'renders the rank_errors partial' do
        post :create_ranking_level, :course_id => @course, :ranking_level => nil
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'rank_errors')
      end
    end
  end

  describe 'POST #edit_ranking_level' do
    context 'ranking_level is found' do
      before { post :edit_ranking_level, :id => @ranking_level }

      it 'assigns @ranking_level' do
        assigns(:ranking_level).should == @ranking_level
      end

      it 'replaces template with informations' do
        response.should have_rjs(:replace_html, 'rank_form')
        response.should render_template(:partial => 'rank_edit_form')
        response.should render_template(:partial => 'rank_errors')
      end
    end

    context 'ranking_level is not found' do
      it 'returns error' do
        expect { post :edit_ranking_level, :id => nil }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'POST #update_ranking_level' do
    context 'valid attributes' do
      before { post :update_ranking_level, :id => @ranking_level, :ranking_level => { :name => 'RLN1', :marks => 100} }

      it 'saves ranking_level' do
        @ranking_level.reload
        @ranking_level.name.should == 'RLN1'
        @ranking_level.marks.should == 100
      end

      it 'replaces template with informations' do
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'ranking_levels')
        response.should render_template(:partial => 'rank_errors')
        response.should render_template(:partial => 'rank_form')
      end
    end

    context 'invalid attributes' do
      before { post :update_ranking_level, :id => @ranking_level, :ranking_level => { :marks => '1Ab'} }
      
      it 'does not save ranking_level' do
        @ranking_level.reload
        @ranking_level.marks.should_not == '1Ab'
      end

      it 'renders the rank_errors partial' do
        response.should have_rjs(:replace_html, 'errors')
        response.should render_template(:partial => 'rank_errors')
      end
    end
  end

  describe 'POST #delete_ranking_level' do
    context 'ranking_level is found' do
      it 'deletes ranking_level' do
        expect { post :delete_ranking_level, :id => @ranking_level }.to change(RankingLevel, :count).by(-1)
      end

      it 'replaces template with informations' do
        post :delete_ranking_level, :id => @ranking_level
        response.should have_rjs(:replace_html, 'category-list')
        response.should render_template(:partial => 'ranking_levels')
        response.should render_template(:partial => 'rank_errors')
        response.should render_template(:partial => 'rank_form')
      end
    end

    context 'ranking_level is not found' do
      it 'returns error' do
        expect { post :delete_ranking_level, :id => nil }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'POST #ranking_level_cancel' do
    before { post :ranking_level_cancel, :course_id => @course }

    it 'assigns informations' do
      assigns(:ranking_levels).should == [@ranking_level]
      assigns(:ranking_level).should be_new_record
    end

    it 'replaces template' do
      response.should have_rjs(:replace_html, 'category-list')
      response.should render_template(:partial => 'ranking_levels')
      response.should render_template(:partial => 'rank_form')
    end
  end

  describe 'POST #change_priority' do
    context 'ranking_level is found' do
      context 'params order is up' do
        before do
          @ranking_level_p1 = FactoryGirl.create(:ranking_level, :priority => 1, :course => @course)
          post :change_priority, :id => @ranking_level, :order => 'up'
        end

        it 'changes priority' do
          @ranking_level.reload
          @ranking_level_p1.reload
          @ranking_level.priority.should == 1
          @ranking_level_p1.priority.should == 10
        end

        it 'assigns informations' do
          assigns(:ranking_level).should be_new_record
          assigns(:ranking_levels).should == [@ranking_level, @ranking_level_p1]
        end

        it 'replaces template with informations' do
          response.should have_rjs(:replace_html, 'category-list')
          response.should render_template(:partial => 'ranking_levels')
        end
      end

      context 'params order is not up' do
        before do
          @ranking_level_p1 = FactoryGirl.create(:ranking_level, :priority => 20, :course => @course)
          post :change_priority, :id => @ranking_level, :order => nil
        end

        it 'changes priority' do
          @ranking_level.reload
          @ranking_level_p1.reload
          @ranking_level.priority.should == 20
          @ranking_level_p1.priority.should == 10
        end

        it 'assigns informations' do
          assigns(:ranking_level).should be_new_record
          assigns(:ranking_levels).should == [@ranking_level_p1, @ranking_level]
        end

        it 'replaces template with informations' do
          response.should have_rjs(:replace_html, 'category-list')
          response.should render_template(:partial => 'ranking_levels')
        end
      end
    end

    context 'ranking_level is not found' do
      it 'returns error' do
        expect { post :change_priority, :id => nil, :order => nil }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

end