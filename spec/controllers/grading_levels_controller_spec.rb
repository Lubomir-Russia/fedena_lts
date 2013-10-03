require 'spec_helper'

describe GradingLevelsController do
  before do
    @grading_level = FactoryGirl.build(:grading_level)
    @batch = FactoryGirl.create(:batch)
    @user = Factory.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      Batch.stub(:active).and_return([@batch])
      GradingLevel.stub(:default).and_return([@grading_level])
      get :index
    end

    it 'assigns @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'assigns @grading_levels' do
      assigns(:grading_levels).should == [@grading_level]
    end
  end

  describe '#new' do
    context 'XHR POST with params id' do
      before do
        GradingLevel.stub(:check_credit).and_return(true)
        xhr :post, :new, :id => @batch.id, :format => 'js'
      end

      it 'assigns @grading_level' do
        assigns(:grading_level).should be_new_record
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @credit to true' do
        assigns(:credit).should be_true
      end

      it 'renders the new template' do
        response.should render_template('new')
      end
    end
  end

  describe 'POST #create' do
    before do
      GradingLevel.stub(:new).and_return(@grading_level)
      Batch.stub(:find).and_return(@batch)
    end

    context 'successful create' do
      before do
        GradingLevel.any_instance.expects(:valid?).returns(true)
      end

      context 'create with param batch_id' do
        before { GradingLevel.stub(:default).and_return([@grading_level]) }

        context 'with html format' do
          before { post :create, :grading_level => { :batch_id => @batch.id }, :format => 'html' }

          it 'assigns @grading_levels' do
            assigns(:grading_levels).should == [@grading_level]
          end

          it 'redirects to the grading_level_url' do
            response.should redirect_to(grading_level_url(assigns(:grading_level)))
          end

          it 'responses to html format' do
            response.content_type.should == Mime::HTML
          end
        end

        context 'with js format' do
          before { post :create, :grading_level => { :batch_id => @batch.id }, :format => 'js' }

          it 'renders the create template' do
            response.should render_template('create')
          end

          it 'responses to js format' do
            response.content_type.should == Mime::JS
          end
        end
      end

      context 'create with param batch_id is nil' do
        before do
          GradingLevel.stub(:for_batch).and_return([@grading_level])
          post :create, :grading_level => { :batch_id => nil }
        end

        it 'assigns @grading_levels' do
          assigns(:grading_levels).should == [@grading_level]
        end
      end
    end

    context 'failed create' do
      before do
        GradingLevel.any_instance.expects(:valid?).returns(false)
      end

      context 'with html format' do
        before { post :create, :grading_level => {}, :format => 'html' }

        it 'assigns @error to true' do
          assigns(:error).should be_true
        end

        it 'renders the new template' do
          response.should render_template('new')
        end

        it 'responses to html format' do
          response.content_type.should == Mime::HTML
        end
      end

      context 'with js format' do
        before { post :create, :grading_level => {}, :format => 'js' }

        it 'renders the create template' do
          response.should render_template('create')
        end

        it 'responses to js format' do
          response.content_type.should == Mime::JS
        end
      end
    end
  end

  describe 'GET #edit' do
    before do
      GradingLevel.stub(:find).and_return(@grading_level)
      Batch.stub(:find).and_return(@batch)
      GradingLevel.stub(:check_credit).and_return(true)

    end

    context 'with html format' do
      before { get :edit, :id => 2, :format => 'html' }

      it 'assigns @grading_level' do
        assigns(:grading_level).should == @grading_level
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @credit to true' do
        assigns(:credit).should be_true
      end

      it 'responses to html format' do
        response.content_type.should == Mime::HTML
      end
    end

    context 'with js format' do
      before { get :edit, :id => 2, :format => 'js' }

      it 'renders the edit template' do
        response.should render_template('edit')
      end

      it 'responses to js format' do
        response.content_type.should == Mime::JS
      end
    end
  end

  describe 'PUT #update' do
    before { GradingLevel.stub(:find).and_return(@grading_level) }

    context 'successful update' do
      before { GradingLevel.any_instance.expects(:valid?).returns(true) }

      context '@grading_level.batch is nil' do
        before do
          @grading_level.batch = nil
          GradingLevel.stub(:default).and_return([@grading_level])

        end

        context 'with html format' do
          before { put :update, :id => 2, :format => 'html' }

          it 'assigns @grading_levels' do
            assigns(:grading_levels).should == [@grading_level]
          end

          it 'redirects to grading_level_url' do
            response.should redirect_to(grading_level_url(assigns(:grading_level)))
          end

          it 'responses to html format' do
            response.content_type.should == Mime::HTML
          end
        end

        context 'with js format' do
          before { put :update, :id => 2, :format => 'js' }

          it 'renders the edit template' do
            response.should render_template('update')
          end

          it 'responses to js format' do
            response.content_type.should == Mime::JS
          end
        end
      end
    end

    context 'failed update' do
      before do
        GradingLevel.any_instance.expects(:valid?).returns(false)
      end

      context 'with html format' do
        before { put :update, :id => 2, :format => 'html' }

        it 'assigns @error to true' do
          assigns(:error).should be_true
        end

        it 'renders the new template' do
          response.should render_template('new')
        end

        it 'responses to html format' do
          response.content_type.should == Mime::HTML
        end
      end

      context 'with js format' do
        before { put :update, :id => 2, :format => 'js' }

        it 'renders the create template' do
          response.should render_template('create')
        end

        it 'responses to js format' do
          response.content_type.should == Mime::JS
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      GradingLevel.stub(:find).and_return(@grading_level)
      @grading_level.batch = @batch
    end

    it 'assigns @batch' do
      delete :destroy, :id => 2
      assigns(:batch).should == @batch
    end

    it 'calls @grading_level.inactivate' do
      @grading_level.should_receive(:inactivate)
      delete :destroy, :id => 2
    end
  end

  describe 'GET #show' do
    context 'param batch_id is blank' do
      before do
        GradingLevel.stub(:default).and_return([@grading_level])
        get :show, :batch_id => ''
      end

      it 'assigns @grading_levels' do
        assigns(:grading_levels).should == [@grading_level]
      end

      it 'renders the show template' do
        response.should render_template('show')
      end
    end

    context 'param batch_id is present' do
      before do
        GradingLevel.stub(:for_batch).and_return([@grading_level])
        Batch.stub(:find).and_return(@batch)
        get :show, :batch_id => @batch.id
      end

      it 'assigns @grading_levels' do
        assigns(:grading_levels).should == [@grading_level]
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end
    end
  end
end