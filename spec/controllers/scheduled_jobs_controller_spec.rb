require 'spec_helper'

describe ScheduledJobsController do
  before do
    @user = Factory.create(:admin_user)
    sign_in(@user)
  end

  describe 'GET #index' do
    context 'jobs is found' do
      before do
        @job = Delayed::Job.enqueue(Batch.new(:job_type => '1'))
      end

      context 'job_object and job_type are not nil' do
        before { get :index, :job_object => 'Batch', :job_type => '1' }
        
        it 'renders the index template' do
          response.should render_template('index')
        end

        it 'assigns @jobs' do
          assigns(:jobs).should == [@job]
        end
      end

      context 'job_object is not nil and job_type is nil' do
        before { get :index, :job_object => 'Batch' }
        
        it 'renders the index template' do
          response.should render_template('index')
        end

        it 'assigns @jobs' do
          assigns(:jobs).should == [@job]
        end
      end
    end

    context 'jobs is not found' do
      before { get :index, :job_object => 'Batch', :job_type => '1' }
      
      it 'renders the index template' do
        response.should render_template('index')
      end

      it 'returns empty' do
        assigns(:jobs).should == []
      end
    end
  end
end