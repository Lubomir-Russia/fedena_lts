require 'spec_helper'

describe Observation do

  it { should belong_to(:observation_group) }
  it { should have_many(:descriptive_indicators) }
  it { should have_many(:assessment_scores).through(:descriptive_indicators) }
  it { should have_many(:cce_reports) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:desc) }

  describe '.active' do
    let!(:observation1) { FactoryGirl.create(:observation, :is_active => true) }
    let!(:observation2) { FactoryGirl.create(:observation, :is_active => false) }

    it 'returns active observation' do
      active_observation = Observation.active
      active_observation.count.should == 1
      active_observation.should include(observation1)
    end
  end

  describe '#next_record' do
    let!(:observation1) { FactoryGirl.create(:observation) }
    let!(:observation_group) { ObservationGroup.new(:observations => [observation1]) }
    let!(:observation) { FactoryGirl.create(:observation, :observation_group => observation_group) }
    before { observation_group.observations.stub(:first).and_return(observation1) }

    it 'returns next_record' do
      observation.next_record.should == observation1
    end
  end

  describe '#prev_record' do
    let!(:observation1) { FactoryGirl.create(:observation) }
    let!(:observation_group) { ObservationGroup.new(:observations => [observation1]) }
    let!(:observation) { FactoryGirl.create(:observation, :observation_group => observation_group) }
    before { observation_group.observations.stub(:last).and_return(observation1) }

    it 'returns prev_record' do
      observation.prev_record.should == observation1
    end
  end
end