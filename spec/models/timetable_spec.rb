require 'spec_helper'

describe Timetable do
  it { should have_many(:timetable_entries).dependent(:destroy) }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:end_date) }

  context 'a exists record' do
    let!(:timetable) { Timetable.create(:start_date => Date.current - 5.days, :end_date => Date.current) }

    describe '#start_date_is_lower_than_end_date' do
      before do
        timetable.start_date = Date.current
        timetable.end_date = Date.current - 10.days
      end

      context 'when start_date > end_date' do
        it 'is invalid' do
          timetable.should be_invalid
        end
      end
    end

    describe '#timetable_in_between_given_dates' do
      let(:timetable1) { Timetable.new(:start_date => Date.current - 7.days, :end_date => Date.current + 3.days) }

      context 'when exists record end_date <= timetable1.end_date && start_date >= timetable1.end_date' do
        it 'is invalid' do
          timetable1.should be_invalid
        end
      end
    end

    describe '#end_date_overlap' do
      let(:timetable1) { Timetable.new(:start_date => Date.current - 20.days, :end_date => Date.current - 3.days) }

      context 'when exists record end_date >= timetable1.end_date >= start_date' do
        it 'is invalid' do
          timetable1.should be_invalid
        end
      end
    end

    describe '#check_start_date_overlap' do
      let(:timetable1) { Timetable.new(:start_date => Date.current - 4.days, :end_date => Date.current - 21.days) }

      context 'when exists record end_date >= timetable1.start_date >= start_date' do
        it 'is invalid' do
          timetable1.should be_invalid
        end
      end
    end

  end
end