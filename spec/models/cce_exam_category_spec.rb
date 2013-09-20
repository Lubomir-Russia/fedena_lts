require 'spec_helper'

describe CceExamCategory do
  it { should have_many(:cce_weightages) }
  it { should have_many(:exam_groups) }
  it { should have_many(:fa_groups) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:desc) }
end