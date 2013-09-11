require 'spec_helper'

describe StudentCategory do
  it { should have_many(:students) }
  #it { should have_many(:fee_category).class_name('FinanceFeeCategory') }

  it { should validate_presence_of(:name) }

  describe 'validate uniqueness of name' do
    before do
      @student_category = StudentCategory.create(:name => 'StudentCategory1', :is_deleted => false)
    end

    context 'record is valid name' do
      it { should validate_uniqueness_of(:name).scoped_to(:is_deleted).case_insensitive }
    end

    context 'record is invalid name' do
      it { should_not validate_uniqueness_of(:name).scoped_to(:is_deleted).case_insensitive.with_message(/different value of is_deleted/) }
    end
  end

  describe '.active name_scope' do
    before do
      @student_category = StudentCategory.create(:name => 'StudentCategory1', :is_deleted => false)
    end

    it "return active user" do
      StudentCategory.active.should == [@student_category]
    end
  end

  describe '#empty_students' do
    before do
      @student_category = StudentCategory.create(:name => 'StudentCategory1')
      @student          = FactoryGirl.create(:student, :student_category_id => @student_category.id)
    end

    it 'returns empty students' do
      @student_category.empty_students
      @student.reload
      @student.student_category_id.should be nil
    end
  end

  describe '#check_dependence' do
    before do
      @student_category  = StudentCategory.create(:name => 'StudentCategory1')
      @student_category2 = StudentCategory.create(:name => 'StudentCategory2')
      @student           = FactoryGirl.create(:student, :student_category_id => @student_category.id)
    end

    it 'existing students' do
      @student_category.check_dependence.should be nil
    end

    it 'no existing students' do
      @student_category2.check_dependence.should be false
    end
  end
end