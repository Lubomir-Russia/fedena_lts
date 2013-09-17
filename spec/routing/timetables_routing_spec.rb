require 'spec_helper'

describe TimetablesController do
  describe 'routing' do
    it 'recognizes and generates #new' do
      { :get => 'timetables/new' }.should route_to(:controller => 'timetables', :action => 'new')
    end

    it 'recognizes and generates #index' do
      { :get => 'timetables' }.should route_to(:controller => 'timetables', :action => 'index')
    end

    it 'recognizes and generates #edit' do
      { :get => 'timetables/1/edit' }.should route_to(:controller => 'timetables', :action => 'edit', :id => '1')
    end

    it 'recognizes and generates #create' do
      { :post => 'timetables' }.should route_to(:controller => 'timetables', :action => 'create')
    end

    it 'recognizes and generates #update' do
      { :put => 'timetables/1' }.should route_to(:controller => 'timetables', :action => 'update', :id => '1')
    end

    it 'recognizes and generates #destroy' do
      { :delete => 'timetables/1' }.should route_to(:controller => 'timetables', :action => 'destroy', :id => '1')
    end
  end
end
