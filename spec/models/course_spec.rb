require 'spec_helper'

describe Course do
  context 'validate course' do
    before do
      @course1 = Factory.create(:course, :is_deleted => false)
      @course2 = Factory.create(:course, :is_deleted => true)
    end

    it { should validate_presence_of(:course_name) }
    it { should validate_presence_of(:code) }
    it { should have_many(:batches) }
    it { should have_many(:batch_groups) }
    it { should have_many(:ranking_levels) }
    it { should have_many(:class_designations) }
    it { should have_many(:subject_amounts) }
    it { should have_and_belong_to_many(:observation_groups) }

    describe '#presence_of_initial_batch' do
      it 'should at latest have a batch' do
        @course1.batches.count.should >= 1
      end
    end

    describe '#inactivate' do
      it 'sets is_deleted true' do
        @course1.inactivate
        @course1.should be_is_deleted
      end
    end

    describe '#full_name' do
      it 'returns full name of course' do
        @course1.full_name.should == "1 A"
      end
    end

    describe '#active_batches' do
      it 'returns all active batches' do
        @course1.active_batches.should == @course1.batches.all(:conditions=>{ :is_active=>true,:is_deleted=>false })
      end
    end

    describe '#has_batch_groups_with_active_batches' do
      it 'should return false' do
        @course1.has_batch_groups_with_active_batches.should be_false
      end

      it 'should return true' do
        @batch_groups = Factory.create(:batch_group, :course => @course1)
        @batch_groups.batches << @course1.batches
        @course1.has_batch_groups_with_active_batches.should be_true
      end
    end

    describe '#cce_enabled?' do
      before { @course1.grading_type = Course::INVERT_GRADINGTYPES["CCE"] }

      it 'should returns true' do
        Configuration.stub(:cce_enabled?).and_return(true)
        @course1.should be_cce_enabled
      end

      it 'should returns false' do
        Configuration.stub(:cce_enabled?).and_return(false)
        @course1.should_not be_cce_enabled
      end
    end

    describe '#gpa_enabled?' do
      before { @course1.grading_type = Course::INVERT_GRADINGTYPES["GPA"] }

      it 'should returns true' do
        Configuration.stub(:has_gpa?).and_return(true)
        @course1.should be_gpa_enabled
      end

      it 'should returns false' do
        Configuration.stub(:has_gpa?).and_return(false)
        @course1.should_not be_gpa_enabled
      end
    end

    describe '#cwa_enabled?' do
      before { @course1.grading_type = Course::INVERT_GRADINGTYPES["CWA"] }

      it 'should returns true' do
        Configuration.stub(:has_cwa?).and_return(true)
        @course1.should be_cwa_enabled
      end

      it 'should returns false' do
        Configuration.stub(:has_cwa?).and_return(false)
        @course1.should_not be_cwa_enabled
      end
    end

    describe '#normal_enabled?' do
      it 'should returns true' do
        @course1.grading_type = "0"
        @course1.should be_normal_enabled
      end
    end

    describe "scope_name test" do
      describe ".active" do
        it "returns active course" do
          Course.active.should == [@course1]
        end
      end

      describe ".deleted" do
        it "returns deleted course" do
          Course.deleted.should == [@course2]
        end
      end

      describe ".cce" do
        it "returns CCE course" do
          @course1.grading_type = Course::INVERT_GRADINGTYPES["CCE"]
          @course1.save
          Course.cce.should == [@course1]
        end
      end
    end

  end
end
