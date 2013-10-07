require 'spec_helper'

describe NewsController do
  before do
    @user = Factory.create(:admin_user)
    @news = FactoryGirl.create(:news, :author => @user)
    
    sign_in(@user)
  end

  describe 'GET #add' do
    before { get :add }

    it 'renders the add template' do
      response.should render_template('add')
    end
  end

  describe 'POST #add' do
    before { post :add, :news => { :title => @news.title, :content => @news.content } }

    it 'assigns flash[:notice]' do
      flash[:notice].should == "#{@controller.t('flash1')}"
    end

    it 'redirects to batch_elective_groups_path' do
      response.should redirect_to(:controller => 'news', :action => 'view')
    end
  end

  describe 'POST #add_comment' do
    context 'comment is created' do
      before { post :add_comment, :comment => { :content => 'abc', :news => @news } }

      it 'assigns @cmnt' do
        assigns(:cmnt).should be_valid
        assigns(:cmnt).should be_kind_of(NewsComment)
      end
    end

    context 'comment is not created' do
      before { post :add_comment }

      it 'assigns @cmnt' do
        assigns(:cmnt).should_not be_valid
      end
    end
  end

  describe 'GET #all' do
    before do
      @news2 = FactoryGirl.create(:news)
      get :all
    end

    it 'assigns @news' do
      assigns(:news).should == [@news, @news2]
    end
  end

  describe 'DELETE #destroy' do
    it 'assigns flash[:notice]' do
      delete :delete, :id => @news
      flash[:notice].should == "#{@controller.t('flash2')}"
    end

    it 'redirects to the batch_elective_groups_path' do
      delete :delete, :id => @news
      response.should redirect_to(:controller => 'news', :action => 'index')
    end
  end

  describe 'DELETE #delete_comment' do
    context 'comment is found' do
      before { @comment = FactoryGirl.create(:news_comment, :author => @user) }
      
      it 'delete @comment' do
        expect { delete :delete_comment, :id => @comment }.to change(NewsComment, :count).by(-1)
      end
    end

    context 'comment is not found' do
      it 'assigns @comment' do
        expect { delete :delete_comment, :id => 12 }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'GET #edit' do
    before { get :edit, :id => @news }

    it 'renders the edit template' do
      response.should render_template('edit')
    end

    it 'assigns @news' do
      assigns(:news).should == @news
    end
  end

  describe 'POST #edit' do
    context 'news is edited' do
      before { post :edit, :id => @news }

      it 'assigns flash[:notice]' do
        flash[:notice].should == "#{@controller.t('flash3')}"
      end

      it 'redirects to the view action' do
        response.should redirect_to(:controller => 'news', :action => 'view')
      end
    end

    context 'news is unedited' do
      before { put :edit, :id => @news }

      it 'assigns flash[:notice]' do
        flash[:notice].should be_nil
      end
    end
  end

  describe 'GET #view' do
    before do
      @newscm = FactoryGirl.create(:news_comment, :news => @news, :author => @user)
      get :view, :id => @news.id
    end

    it 'renders the view template' do
      response.should render_template('view')
    end

    it 'assigns @news and @comments' do
      assigns(:news).should == @news
      assigns(:comments).should == [@newscm]
    end
  end

  describe 'GET #index' do
    context 'params[:query] is nil' do
      before { get :index }

      it 'renders the index template' do
        response.should render_template('index')
      end

      it 'assigns @news' do
        assigns(:news).should == []
      end
    end

    context 'params[:query] is not nil' do
      context 'news is not found' do
        before { get :index, :query => 'abv132123213897123'.to_param }

        it 'renders the index template' do
          response.should render_template('index')
        end

        it 'assigns @news' do
          assigns(:news).should == []
        end
      end

      context 'news is found' do
        before { get :index, :query => 'title'.to_param }

        it 'renders the index template' do
          response.should render_template('index')
        end

        it 'assigns @news' do
          assigns(:news).should == [@news]
        end
      end
    end
  end

  describe 'GET #search_news_ajax' do
    context 'news is found' do
      before do
        xhr :get, :search_news_ajax, :query => 'title'.to_param
      end

      it 'do not renders the layout' do
        response.layout.should be_false
      end

      it 'assigns @news' do
        assigns(:news).should == [@news]
      end
    end

    context 'news is not found' do
      before do
        xhr :get, :search_news_ajax, :query => '1213871238612312938'.to_param
      end

      it 'assigns @news' do
        assigns(:news).should == []
      end
    end
  end

  describe 'GET #comment_approved' do
    before do
      @newscm = FactoryGirl.create(:news_comment, 
        :news => @news, 
        :author => @user,
        :is_approved => false)
      put :comment_approved, :id => @newscm
    end

    it 'assigns @news' do
      assigns(:comment).is_approved.should be_true
    end
  end

end
