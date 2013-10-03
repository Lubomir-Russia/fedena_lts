require 'spec_helper'

describe ClassTimingsController do
  before do
    @batch = FactoryGirl.create(:batch)
    @class_timing = FactoryGirl.create(:class_timing)
    @user = Factory.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    before do
      Batch.stub(:active).and_return([@batch])
      ClassTiming.stub(:find_all_by_batch_id_and_is_deleted).with(nil, false, :order => 'start_time ASC').and_return([@class_timing])
      get :index
    end

    it 'renders the index template' do
      response.should render_template('index')
    end

    it 'assigns all active Batch as @batches' do
      assigns(:batches).should == [@batch]
    end

    it 'assigns all Classtiming with conditions to @class_timing' do
      assigns(:class_timings).should == [@class_timing]
    end
  end

  describe 'XHR #new' do
    before do
      xhr :post, :new, {:id => @batch.id}
    end

    it 'renders the new template' do
      response.should render_template('new')
    end

    it 'assigns @class_timing' do
      assigns(:class_timing).should be_new_record
    end
  end

  describe 'GET #edit' do
    before do
      get :edit, :id => @class_timing
    end

    it 'renders the edit template' do
      response.should render_template('edit')
    end

    it 'assigns @class_timing' do
      assigns(:class_timing).should == @class_timing
    end
  end

  describe 'GET #show' do
    context 'batch_id is present' do
      before do
        ClassTiming.stub(:active_for_batch).and_return([@class_timing])
        get :show, :batch_id => @batch.id
      end

      it 'renders the edit template' do
        response.should render_template('show')
      end

      it 'assigns @batch' do
        assigns(:batch).should == @batch
      end

      it 'assigns @class_timings' do
        assigns(:class_timings).should == [@class_timing]
      end
    end

    context 'batch_id is blank' do
      before do
        ClassTiming.stub(:find_all_by_batch_id_and_is_deleted).with(nil, false).and_return([@class_timing])
        get :show
      end

      it 'assigns @class_timings' do
        assigns(:class_timings).should == [@class_timing]
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'does update is_deleted to true' do
      delete :destroy, :id => @class_timing
      assigns(:class_timing).should be_is_deleted
    end
  end

  describe 'POST #create' do
    before { ClassTiming.stub(:new).with({ 'these' => 'params' }).and_return(@class_timing) }

    context 'successful create' do
      before { ClassTiming.any_instance.expects(:valid?).returns(true) }

      context '@class_timing.batch is nil' do
        before do
          @class_timing.batch = nil
          ClassTiming.stub(:find_all_by_batch_id_and_is_deleted).with(nil, false, :order => 'start_time ASC').and_return([@class_timing])
        end

        context 'with html format' do
          before { post :create, :class_timing => { 'these' => 'params'}, :format => 'html' }

          it 'assigns @class_timings' do
            assigns(:class_timings).should == [@class_timing]
          end

          it 'redirects to class_timing_url' do
            response.should redirect_to(class_timing_url(assigns(:class_timing)))
          end

          it 'responses to html format' do
            response.content_type.should == Mime::HTML
          end
        end

        context 'with js format' do
          before { post :create, :class_timing => { 'these' => 'params'}, :format => 'js' }

          it 'renders the create template' do
            response.should render_template('create')
          end

          it 'responses to js format' do
            response.content_type.should == Mime::JS
          end
        end
      end

      context '@class_timing.batch is present' do
        before do
          @class_timing.batch = @batch
          ClassTiming.stub(:for_batch).and_return([@class_timing])
          post :create, :class_timing => { 'these' => 'params'}
        end

        it 'assigns @class_timings' do
          assigns(:class_timings).should == [@class_timing]
        end
      end
    end

    context 'failed create' do
      before { ClassTiming.any_instance.expects(:valid?).returns(false) }

      context 'with html format' do
        before { post :create, :class_timing => { 'these' => 'params' }, :format => 'html' }

        it 'assigns @error to true' do
          assigns(:error).should be_true
        end

        it 'renders the new template' do
          response.should render_template('new')
        end

        it 'responses to js format' do
          response.content_type.should == Mime::HTML
        end
      end

      context 'with html format' do
        before { post :create, :class_timing => { 'these' => 'params' }, :format => 'js' }

        it 'renders the create template' do
          response.should render_template('create')
        end

        it 'responses to js format' do
          response.content_type.should == Mime::JS
        end
      end
    end
  end

  describe 'PUT #update' do
    before { ClassTiming.stub(:find).and_return(@class_timing) }

    context 'successful update' do
      before { ClassTiming.any_instance.expects(:valid?).returns(true) }

      context '@class_timing.batch is nil' do
        before do
          @class_timing.batch = nil
          ClassTiming.stub(:find_all_by_batch_id).with(nil, :order =>'start_time ASC').and_return([@class_timing])
        end

        context 'with html format' do
          before { put :update, :id => 2, :format => 'html' }

          it 'assigns @class_timings' do
            assigns(:class_timings).should == [@class_timing]
          end

          it 'redirects to class_timing_url' do
            response.should redirect_to(class_timing_url(assigns(:class_timing)))
          end

          it 'responses to html format' do
            response.content_type.should == Mime::HTML
          end
        end

        context 'with js format' do
          before { put :update, :id => 2, :format => 'js' }

          it 'renders the update template' do
            response.should render_template('update')
          end

          it 'responses to html format' do
            response.content_type.should == Mime::JS
          end
        end
      end

      context '@class_timing.batch is nil' do
        before do
          @class_timing.batch = @batch
          ClassTiming.stub(:for_batch).and_return([@class_timing])
          put :update, :id => 2
        end

        it 'assigns @class_timings' do
          assigns(:class_timings).should == [@class_timing]
        end
      end
    end

    context 'failed update' do
      before { ClassTiming.any_instance.expects(:valid?).returns(false) }

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

        it 'responses to html format' do
          response.content_type.should == Mime::JS
        end
      end
    end
  end
end