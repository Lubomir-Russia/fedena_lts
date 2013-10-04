require 'spec_helper'

describe Batch do
  it { should belong_to(:course) }
  it { should have_many(:students) }
  it { should have_many(:exam_groups) }
  it { should have_many(:archived_students) }
  it { should have_many(:grading_levels).conditions(:is_deleted => false) }
  it { should have_many(:subjects).conditions(:is_deleted => false) }
  it { should have_many(:employees_subjects).through(:subjects) }
  it { should have_many(:fee_category).class_name("FinanceFeeCategory") }
  it { should have_many(:elective_groups) }
  it { should have_many(:grouped_exam_reports) }
  it { should have_many(:grouped_batches) }
  it { should have_many(:finance_fee_collections) }
  it { should have_many(:finance_transactions).through(:students) }
  it { should have_many(:batch_events) }
  it { should have_many(:events).through(:batch_events) }
  it { should have_many(:batch_fee_discounts) }
  it { should have_many(:student_category_fee_discounts) }
  it { should have_many(:attendances) }
  it { should have_many(:subject_leaves) }
  it { should have_many(:timetable_entries) }
  it { should have_many(:cce_reports) }
  it { should have_many(:assessment_scores) }
  it { should have_and_belong_to_many(:graduated_students).class_name('Student') }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:started_on) }
  it { should validate_presence_of(:ended_on) }

  describe '.active' do
    let(:course) { FactoryGirl.create(:course) }
    let!(:inactive_batch) { FactoryGirl.create(:batch, :is_active => false, :course => course) }

    it 'returns active batch' do
      Batch.active.should == course.batches
    end
  end

  describe '.inactive' do
    let(:course) { FactoryGirl.create(:course) }
    let!(:inactive_batch) { FactoryGirl.create(:batch, :is_active => false, :course => course) }

    it 'returns inactive batch' do
      Batch.inactive.should == [inactive_batch]
    end
  end

  describe '.deleted' do
    let(:course) { FactoryGirl.create(:course) }
    let!(:deleted_batch) { FactoryGirl.create(:batch, :is_deleted => true, :course => course) }

    it 'returns deleted batch' do
      Batch.deleted.should == [deleted_batch]
    end
  end

  describe '.cce' do
    let!(:course) { FactoryGirl.create(:course, :grading_type => '3') }

    it 'returns cce batch' do
      Batch.cce.should == course.batches
    end
  end

  describe '#valid_date' do
    context 'end_date is before start_date' do
      let!(:batch) { FactoryGirl.build(:batch, 
        :started_on => Date.current, 
        :ended_on   => Date.current - 2.days) 
      }

      it 'returns error' do
        batch.should be_invalid
        batch.errors[:started_on].should == I18n.t('should_be_before_end_date')
      end
    end
  end

  describe '#full_name' do
    let(:batch) { FactoryGirl.build(:batch,
      :name  => '123',
      :course => FactoryGirl.build(:course, :code => 'Abc')) }

    it 'returns full_name' do
      batch.full_name.should == 'Abc - 123'
    end
  end

  describe '#course_section_name' do
    let(:batch) { FactoryGirl.build(:batch,
      :course => FactoryGirl.build(:course, 
        :course_name  => 'Fedena',
        :section_name => '2013')) }

    it 'returns course_section_name' do
      batch.course_section_name.should == 'Fedena - 2013'
    end
  end

  describe '#inactivate' do
    let!(:batch) { FactoryGirl.create(:batch) }
    let!(:subject) { FactoryGirl.create(:subject, :batch => batch) }
    before { FactoryGirl.create(:employees_subject, :subject => subject) }

    it 'update_attribute and destroy employees_subjects' do
      lambda { batch.inactivate }.should change { EmployeesSubject.count }.by(-1)
      batch.is_deleted.should be_true
    end
  end

  describe '#grading_level_list' do
    context 'grading_levels is not empty' do
      let(:batch) { FactoryGirl.create(:batch) }
      let!(:grading_level) { FactoryGirl.create(:grading_level, :batch => batch) }

      it 'returns grading_level_list' do
        batch.grading_level_list.should == [grading_level]
      end
    end

    context 'grading_levels is empty' do
      let(:batch) { FactoryGirl.create(:batch) }

      it 'returns nil' do
        batch.grading_level_list.should == []
      end
    end
  end

  describe '#fee_collection_dates' do
    context 'FinanceFeeCollection is found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let!(:ffee_collection) { FactoryGirl.create(:finance_fee_collection, :batch => batch) }

      it 'returns finance_fee_collection' do
        batch.fee_collection_dates.should == [ffee_collection]
      end
    end

    context 'FinanceFeeCollection is not found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let!(:ffee_collection) { FactoryGirl.create(:finance_fee_collection, :batch => batch, :is_deleted => true) }

      it 'returns nil' do
        batch.fee_collection_dates.should == []
      end
    end
  end

  describe '#all_students' do
    context 'student is found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let!(:student) { FactoryGirl.create(:student, :batch => batch) }
      before { FactoryGirl.create(:student) }

      it 'returns all students' do
        batch.all_students.should == [student]
      end
    end
  end

  describe '#normal_batch_subject' do
    context 'subject is found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let!(:subject) { FactoryGirl.create(:subject, 
        :batch => batch,
        :elective_group_id => nil) }

      it 'returns subject' do
        batch.normal_batch_subject.should == [subject]
      end
    end

    context 'subject is not found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let!(:subject) { FactoryGirl.create(:subject, 
        :batch => batch,
        :elective_group_id => 1) }

      it 'returns nil' do
        batch.fee_collection_dates.should == []
      end
    end
  end

  describe '#elective_batch_subject' do
    context 'subject is not found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let(:elect_group) { FactoryGirl.create(:elective_group) }
      let!(:subject) { FactoryGirl.create(:subject, 
        :batch => batch,
        :elective_group_id => nil) }

      it 'returns nil' do
        batch.elective_batch_subject(elect_group).should == []
      end
    end

    context 'subject is found' do
      let(:batch) { FactoryGirl.create(:batch) }
      let(:elect_group) { FactoryGirl.create(:elective_group) }
      let!(:subject) { FactoryGirl.create(:subject, 
        :batch => batch,
        :elective_group => elect_group) }

      it 'returns subject' do
        batch.elective_batch_subject(elect_group).should == [subject]
      end
    end
  end

  describe '#all_elective_subjects' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:elect_group) { FactoryGirl.create(:elective_group, :batch => batch) }

    context 'subject is found' do
      let!(:subject) { FactoryGirl.create(:subject, 
        :batch => batch,
        :elective_group => elect_group) }
      before { FactoryGirl.create(:subject, 
        :batch => batch,
        :is_deleted => true,
        :elective_group => elect_group) }

      it 'returns subject' do
        batch.all_elective_subjects.should == [subject]
      end
    end

    context 'subject is not found' do
      it 'returns nil' do
        batch.all_elective_subjects.should == []
      end
    end
  end

  describe '#has_own_weekday' do
    let(:batch) { FactoryGirl.create(:batch) }

    context 'weekday is found' do
      before { FactoryGirl.create(:weekday, :batch => batch) }

      it 'returns true' do
        batch.has_own_weekday.should be_true
      end
    end

    context 'weekday is not found' do
      it 'returns false' do
        batch.has_own_weekday.should be_false
      end
    end

    context 'weekday is deleted' do
      before { FactoryGirl.create(:weekday, :batch => batch, :is_deleted => true) }

      it 'returns false' do
        batch.has_own_weekday.should be_false
      end
    end
  end

  describe '#allow_exam_acess' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:employee) { FactoryGirl.create(:employee) }
    
    context 'subject is found' do
      context 'batch_id is match' do
        let(:subject) { FactoryGirl.create(:subject, :batch => batch) }
        before { FactoryGirl.create(:employees_subject, :subject => subject, :employee => employee) }

        it 'returns true' do
          batch.allow_exam_acess(employee.user).should be_true
        end
      end

      context 'batch_id is not match' do
        let(:subject) { FactoryGirl.create(:subject) }
        before { FactoryGirl.create(:employees_subject, :subject => subject, :employee => employee) }

        it 'returns false' do
          batch.allow_exam_acess(employee.user).should be_false
        end
      end
    end

    context 'subject is not found' do
      it 'returns true' do
        batch.allow_exam_acess(employee.user).should be_true
      end
    end
  end

  describe '#is_a_holiday_for_batch' do
    let(:batch) { FactoryGirl.create(:batch) }

    context 'event is a holiday for batch' do
      before { FactoryGirl.create(:event, 
        :is_holiday => true,
        :start_date => Date.current.to_datetime - 3.days,
        :end_date => Date.current.to_datetime + 3.days) }

      it 'returns true' do
        batch.is_a_holiday_for_batch?(Date.current).should be_true
      end
    end

    context 'event is not a holiday for batch' do
      before { FactoryGirl.create(:event,
        :is_holiday => true,
        :start_date => Date.current.to_datetime + 1.days,
        :end_date => Date.current.to_datetime + 3.days) }

      it 'returns false' do
        batch.is_a_holiday_for_batch?(Date.current).should be_false
      end
    end
  end

  describe '#holiday_event_dates' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:current_datetime) { Date.current.to_datetime }

    context 'event is a holiday' do
      before do
        @event1 = FactoryGirl.create(:event,
          :is_holiday => true,
          :start_date => current_datetime + 1.days,
          :end_date => current_datetime + 3.days)
        @event2 = FactoryGirl.create(:event,
          :is_holiday => true,
          :is_common => true,
          :start_date => current_datetime - 1.days,
          :end_date => current_datetime + 1.days)
        FactoryGirl.create(:event)
        FactoryGirl.create(:batch_event, :event => @event1, :batch => batch)
        @event_dates = @event1.dates + @event2.dates
      end

      it 'returns holiday_event_dates' do
        batch.holiday_event_dates.should == @event_dates
      end
    end

    context 'event is not a holiday' do
      before { FactoryGirl.create(:event, :is_common => true) }

      it 'returns nil' do
        batch.holiday_event_dates.should == []
      end
    end
  end

  describe '#return_holidays' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:current_datetime) { Date.current.to_datetime }

    context 'event is a holiday' do
      before do
        @event1 = FactoryGirl.create(:event,
          :is_holiday => true,
          :start_date => current_datetime + 1.days,
          :end_date => current_datetime + 3.days)
        @event2 = FactoryGirl.create(:event,
          :is_holiday => true,
          :is_common => true,
          :start_date => current_datetime - 1.days,
          :end_date => current_datetime + 1.days)
        FactoryGirl.create(:event)
        FactoryGirl.create(:batch_event, :event => @event1, :batch => batch)
        @event_dates = @event1.dates
      end

      it 'returns holiday_event_dates' do
        batch.return_holidays(current_datetime, current_datetime + 5.days).should == @event_dates
      end
    end

    context 'event is not a holiday' do
      before { FactoryGirl.create(:event, :is_common => true) }

      it 'returns nil' do
        batch.return_holidays(current_datetime, current_datetime + 5.days).should == []
      end
    end
  end

  describe '#find_working_days' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:idatetime) { Date.current.to_datetime }

    context 'holiday event is available' do
      before do
        FactoryGirl.create(:event,
          :is_common => true,
          :is_holiday => true,
          :start_date => idatetime,
          :end_date => idatetime + 2.days)
        FactoryGirl.create(:weekday, :weekday => '6', :day_of_week => 2, :batch => batch)
        FactoryGirl.create(:weekday, :weekday => '2', :day_of_week => 5, :batch => batch)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @range = (idatetime.to_date + 2.days..idatetime.to_date + 6.days).select{ |d| weekdays.include? d.wday }
      end

      it 'returns working_days' do
        batch.find_working_days(idatetime, idatetime + 8.days).should == @range
      end
    end

    context 'holiday event is unavailable' do
      before do
        FactoryGirl.create(:weekday, :weekday => '1', :day_of_week => 1, :batch => batch)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @range = (idatetime.to_date..idatetime.to_date + 10.days).select{ |d| weekdays.include? d.wday }
      end

      it 'returns working_days' do
        batch.find_working_days(idatetime, idatetime + 10.days).should == @range
      end
    end
  end

  describe '#working_days' do
    let(:input_date) { Date.new(2013, 10, 22) }
    let(:batch) { FactoryGirl.create(:batch, :started_on => input_date) }

    context 'holiday event is available' do
      before do
        FactoryGirl.create(:event,
          :is_common => true,
          :is_holiday => true,
          :start_date => input_date.to_datetime,
          :end_date => input_date.to_datetime + 2.days)
        FactoryGirl.create(:weekday, :weekday => '1', :day_of_week => 1, :batch => batch)
        FactoryGirl.create(:weekday, :weekday => '2', :day_of_week => 2, :batch => batch)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @range = (input_date + 2.days..input_date.end_of_month).select{ |d| weekdays.include? d.wday }
      end

      it 'returns working_days' do
        batch.working_days(input_date).should == @range
      end
    end

    context 'holiday event is unavailable' do
      before do
        FactoryGirl.create(:weekday, :weekday => '1', :day_of_week => 1, :batch => batch)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @range = (input_date..input_date.end_of_month).select{ |d| weekdays.include? d.wday }
      end

      it 'returns working_days' do
        batch.working_days(input_date).should == @range
      end
    end
  end

  describe '#academic_days' do
    let(:input_date) { Date.current }
    let!(:batch) { FactoryGirl.create(:batch, :started_on => input_date - 6.days) }

    context 'holiday event is available' do
      before do
        FactoryGirl.create(:event,
          :is_common => true,
          :is_holiday => true,
          :start_date => input_date.to_datetime - 1.days,
          :end_date => input_date.to_datetime)
        FactoryGirl.create(:weekday, :weekday => '0', :day_of_week => 0, :batch => batch)
        FactoryGirl.create(:weekday, :weekday => '6', :day_of_week => 6, :batch => batch)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @range = (input_date - 6.days..input_date - 2.days).select{ |d| weekdays.include? d.wday }
      end

      it 'returns academic_days' do
        batch.academic_days.should == @range
      end
    end

    context 'holiday event is unavailable' do
      before do
        FactoryGirl.create(:weekday, :batch => batch)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @range = (input_date - 6.days..input_date).select{ |d| weekdays.include? d.wday }
      end

      it 'returns academic_days' do
        batch.academic_days.should == @range
      end
    end
  end

  describe '#total_subject_hours' do
    let(:idatetime) { Date.current.to_datetime }
    let(:batch) { FactoryGirl.create(:batch, :started_on => idatetime - 6.days) }
    let(:weekday) { FactoryGirl.create(:weekday, :weekday => '6', :day_of_week => 6, :batch => batch) }
    let(:timetable) { FactoryGirl.build(:timetable, :start_date => Date.current - 7.days, :end_date => Date.current + 7.days) }
    let(:class_timing) { FactoryGirl.build(:class_timing, :is_deleted => false) }

    context 'subject_id is equal 0' do
      before do
        @subject = FactoryGirl.create(:subject, :batch => batch)
        FactoryGirl.create(:timetable_entry,
          :subject => @subject,
          :weekday => weekday,
          :timetable => timetable,
          :class_timing => class_timing)
        FactoryGirl.create(:timetable_entry, :subject => @subject)
      end

      it 'returns total_subject_hours' do
        batch.total_subject_hours(@subject.id).should == 1
      end
    end

    context 'subject_id is not equal 0' do
      before do
        @other_weekday = FactoryGirl.create(:weekday, :weekday => '0', :day_of_week => 0, :batch => batch)
        FactoryGirl.create(:timetable_entry,
          :batch => batch,
          :weekday => weekday,
          :timetable => timetable,
          :class_timing => class_timing)
        FactoryGirl.create(:timetable_entry,
          :batch => batch,
          :weekday => @other_weekday,
          :timetable => timetable,
          :class_timing => class_timing)
      end

      it 'returns total_subject_hours' do
        batch.total_subject_hours(0).should == 2
      end
    end
  end

  describe '#find_batch_rank' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:student1) { FactoryGirl.create(:student, :batch => batch) }
    let(:student2) { FactoryGirl.create(:student, :batch => batch) }

    context 'score is not nil' do
      before do
        FactoryGirl.create(:grouped_exam_report, 
          :batch => batch,
          :student => student1,
          :score_type => 'c',
          :marks => 72)
        FactoryGirl.create(:grouped_exam_report, 
          :batch => batch,
          :student => student2,
          :score_type => 'c',
          :marks => 86)
      end

      it 'returns ranked_students' do
        batch.find_batch_rank.should == [[1, 86, student2.id, student2], [2, 72, student1.id, student1]]
      end
    end

    context 'score is nil' do
      before { FactoryGirl.create(:grouped_exam_report, :batch => batch, :student => student1, :score_type => 'f') }

      it 'returns ranked_students' do
        batch.find_batch_rank.should == [[1, 0, student1.id, student1]]
      end
    end
  end

  describe '#find_attendance_rank' do
    let(:idate) { Date.current }
    let(:batch) { FactoryGirl.create(:batch) }

    context 'students and working_days is not blank' do
      let!(:student1) { FactoryGirl.create(:student, :batch => batch) }
      let!(:student2) { FactoryGirl.create(:student, :batch => batch) }

      context 'attendances is found' do
        before do
          FactoryGirl.create(:weekday, :batch => batch)
          FactoryGirl.create(:weekday, :batch => batch, :weekday => "2", :day_of_week => 2) 
          FactoryGirl.create(:attendance, 
            :student => student1,
            :batch => batch,
            :month_date => idate + 3.days,
            :forenoon => true,
            :afternoon => true)
          FactoryGirl.create(:attendance, 
            :student => student2,
            :batch => batch,
            :month_date => idate + 5.days,
            :forenoon => false,
            :afternoon => true)
        end

        it 'returns ranked_students' do
          result = [[2, 50, student1.first_name, 2, 1, student1], [1, 75, student2.first_name, 2, 1.5, student2]]
          batch.find_attendance_rank(idate, idate + 6.days).should == result
        end
      end

      context 'attendances is not found' do
        before do
          FactoryGirl.create(:weekday, :batch => batch, :weekday => "0", :day_of_week => 0)
          FactoryGirl.create(:weekday, :batch => batch, :weekday => "3", :day_of_week => 3) 
        end

        it 'returns ranked_students' do
          result = [[1, 100, student1.first_name, 2, 2, student1], [1, 100, student2.first_name, 2, 2, student2]]
          batch.find_attendance_rank(idate, idate + 6.days).should == result
        end
      end
    end

    context 'students or working_days is blank' do
      it 'returns nil' do
        batch.find_attendance_rank(idate, idate + 1.months).should == []
      end
    end
  end

  describe '#gpa_enabled?' do
    let!(:batch) { FactoryGirl.create(:batch, :course => FactoryGirl.build(:course)) }

    context 'gpa is enabled in Configuration and grading type is GPA' do
      before do
        Configuration.stub(:has_gpa?).and_return(true)
        batch.course.grading_type = Batch::INVERT_GRADINGTYPES['GPA']
      end

      it 'returns true' do
        batch.should be_gpa_enabled
      end
    end

    context 'gpa is disabled in Configuration' do
      before do
        Configuration.stub(:has_gpa?).and_return(false)
      end

      it 'returns false' do
        batch.should_not be_gpa_enabled
      end
    end

    context 'gpa is enabled in Configuration and grading type is not GPA' do
      before do
        Configuration.stub(:has_gpa?).and_return(true)
        batch.course.grading_type = Batch::INVERT_GRADINGTYPES['CCE']
      end

      it 'returns false' do
        batch.should_not be_gpa_enabled
      end
    end
  end

  describe '#cwa_enabled?' do
    let!(:batch) { FactoryGirl.create(:batch, :course => FactoryGirl.build(:course)) }

    context 'cwa is enabled in Configuration and grading type is CWA' do
      before do
        Configuration.stub(:has_cwa?).and_return(true)
        batch.course.grading_type = Batch::INVERT_GRADINGTYPES['CWA']
      end

      it 'returns true' do
        batch.should be_cwa_enabled
      end
    end

    context 'cwa is disabled in Configuration' do
      before do
        Configuration.stub(:has_cwa?).and_return(false)
      end

      it 'returns false' do
        batch.should_not be_cwa_enabled
      end
    end

    context 'cwa is enabled in Configuration and grading type is not CWA' do
      before do
        Configuration.stub(:has_cwa?).and_return(true)
        batch.course.grading_type = Batch::INVERT_GRADINGTYPES['CCE']
      end

      it 'returns false' do
        batch.should_not be_cwa_enabled
      end
    end
  end

  describe '#normal_enabled?' do
    let!(:batch) { FactoryGirl.create(:batch, :course => FactoryGirl.build(:course)) }

    context 'grading type is nil' do
      before { batch.course.grading_type = nil }

      it 'returns true' do
        batch.should be_normal_enabled
      end
    end

    context 'grading type is 0' do
      before { batch.course.grading_type = '0' }

      it 'returns true' do
        batch.should be_normal_enabled
      end
    end
  end

  describe '#subject_hours' do
    let(:idate) { Date.current }
    let(:batch) { FactoryGirl.create(:batch, :started_on => idate - 7.days) }
    let!(:timetable) { FactoryGirl.build(:timetable, :start_date => idate - 7.days, :end_date => idate + 7.days) }

    context 'entries is found' do
      let!(:subject) { FactoryGirl.create(:subject, :batch => batch) }
      let!(:weekday) { FactoryGirl.create(:weekday) }

      before do
        @timetable_entry = FactoryGirl.create(:timetable_entry,
          :subject => subject,
          :batch => batch,
          :weekday => weekday,
          :timetable => timetable)
        weekdays = Weekday.weekday_by_day(batch.id).keys
        @day = (idate - 6.days..idate).select{ |d| weekdays.include? d.wday }
      end

      context 'subject_id is not equal 0' do
        it 'returns subject_hours' do
          batch.subject_hours(idate - 6.days, idate, subject.id).keys.should include(@day.first)
          batch.subject_hours(idate - 6.days, idate, subject.id).values.should include([@timetable_entry])
        end
      end

      context 'subject_id is equal 0' do
        it 'returns subject_hours' do
          batch.subject_hours(idate - 6.days, idate, 0).keys.should include(@day.first)
          batch.subject_hours(idate - 6.days, idate, 0).values.should include([@timetable_entry])
        end
      end
    end

    context 'entries is not found' do
      it 'returns nil' do
        batch.subject_hours(idate - 6.days, idate, 0).should == {}
      end
    end
  end

  describe '#fa_groups' do
    let(:batch) { FactoryGirl.create(:batch) }

    context 'fa_groups is found' do
      before do
        @subject = FactoryGirl.create(:subject, :batch => batch)
        @fa_group = FactoryGirl.create(:fa_group)
        @fa_group.subjects << @subject
      end

      it 'returns fa_group' do
        batch.fa_groups.should == [@fa_group]
      end
    end

    context 'fa_groups is not found' do
      before do
        @subject = FactoryGirl.create(:subject, :batch => batch)
      end

      it 'returns empty' do
        batch.fa_groups.should == []
      end
    end
  end

  describe '#employees' do
    context 'employee is found' do
      let(:batch) { FactoryGirl.create(:batch, :employee_id => '1,2') }
      let!(:employee1) { FactoryGirl.create(:employee, :id => '1') }
      let!(:employee2) { FactoryGirl.create(:employee, :id => '2') }

      it 'returns employees' do
        batch.employees.should == [employee1, employee2]
      end
    end

    context 'employee is not found' do
      let(:batch) { FactoryGirl.create(:batch) }
      
      it 'returns nil' do
        batch.employees.should == []
      end
    end
  end

  describe '#delete_student_cce_report_cache' do
    let(:batch) { FactoryGirl.create(:batch) }
    let(:student) { FactoryGirl.create(:student) }

    it 'delete report cache' do
      batch.delete_student_cce_report_cache.should be_true
    end
  end

  describe '#check_credit_points' do
    context 'grading_levels is empty' do
      let(:batch) { FactoryGirl.create(:batch) }

      it 'returns true' do
        batch.check_credit_points.should == true
      end
    end

    context 'grading_levels is not empty' do
      let(:batch) { FactoryGirl.create(:batch) }

      context 'credit_points is nil' do
        let!(:grading_level) { FactoryGirl.create(:grading_level, :batch => batch) }

        it 'returns true' do
          batch.check_credit_points.should == false
        end
      end

      context 'credit_points is not nil' do
        let!(:grading_level) { FactoryGirl.create(:grading_level, :batch => batch, :credit_points => 12) }

        it 'returns false' do
          batch.check_credit_points.should == true
        end
      end
    end
  end

  describe '#user_is_authorized' do
    let(:batch) { FactoryGirl.create(:batch, :employee_id => '123') }
      let!(:employee) { FactoryGirl.create(:employee, :id => '123') }

    context 'user is found' do
      it 'returns true' do
        batch.user_is_authorized?(employee.user).should be_true
      end
    end

     context 'user is not found' do
      let!(:user) { FactoryGirl.create(:admin_user) }

      it 'returns false' do
        batch.user_is_authorized?(user).should be_false
      end
    end
  end

  describe '#perform' do
    context 'job_type equal 1' do
      describe '#generate_batch_reports' do
        let(:course) { FactoryGirl.build(:course) }
        let!(:batch) { FactoryGirl.create(:batch, :course => course, :job_type => '1') }
        let!(:student) { FactoryGirl.create(:student, :batch => batch) }
        let!(:subject) { FactoryGirl.create(:subject, :batch => batch, :credit_hours => 1.5) }
        context 'grouped_exams and students are not empty' do
          before do
            @exam_group = FactoryGirl.create(:exam_group, :batch => batch)
            FactoryGirl.create(:grouped_exam, 
              :batch_id => batch.id,
              :exam_group_id => @exam_group.id,
              :weightage => 20)
            FactoryGirl.create(:grouped_exam_report, :batch => batch, :student => student)
          end

          context 'exam is found' do
            let!(:exam) { FactoryGirl.create(:exam, :exam_group => @exam_group, :subject => subject) }

            context 'grading_type.nil? or normal_enabled?' do
              before { FactoryGirl.create(:exam_score, :student => student, :exam => exam, :marks => 60) }

              it 'generate reports' do
                batch.perform
                GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student.id, subject.id, batch.id, 's').marks.should == 12
                GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student.id, @exam_group.id, 'e').marks.should == 60
                GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id, batch.id, "c").marks.should == 12
              end
            end

            context 'gpa_enabled?' do
              before do
                Configuration.stub(:has_gpa?).and_return(true)
                batch.course.grading_type = Batch::INVERT_GRADINGTYPES['GPA']
                @grading_level = FactoryGirl.create(:grading_level, :credit_points => 50, :batch => batch)
                FactoryGirl.create(:exam_score,
                  :student => student,
                  :exam => exam,
                  :marks => 60,
                  :grading_level => @grading_level)
              end

              it 'generate reports' do
                batch.perform
                GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student.id, subject.id, batch.id, 's').marks.should == 10
                GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student.id, @exam_group.id, 'e').marks.should == 50
                GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id, batch.id, "c").marks.should == 10
              end
            end

            context 'cwa_enabled?' do
              before do
                Configuration.stub(:has_cwa?).and_return(true)
                batch.course.grading_type = Batch::INVERT_GRADINGTYPES['CWA']
                @grading_level = FactoryGirl.create(:grading_level, :credit_points => 50, :batch => batch)
                FactoryGirl.create(:exam_score,
                  :student => student,
                  :exam => exam,
                  :marks => 70,
                  :grading_level => @grading_level)
              end

              it 'generate reports' do
                batch.perform
                GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student.id, subject.id, batch.id, 's').marks.should == 14
                GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student.id, @exam_group.id, 'e').marks.should == 70
                GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id, batch.id, "c").marks.should == 14
              end
            end
          end

          context 'exam is not found' do
            it 'do not generate reports' do
              lambda { batch.perform }.should change(GroupedExamReport, :count).by(-1)
            end
          end
        end

        context 'grouped_exams or students are empty' do
          it 'do not generate reports' do
            lambda { batch.perform }.should change(GroupedExamReport, :count).by(0)
          end
        end
      end
    end

    context 'job_type equal 2' do
      describe '#generate_previous_batch_reports' do
        let(:course) { FactoryGirl.build(:course) }
        let(:batch) { FactoryGirl.create(:batch, :course => course, :job_type => '2') }
        let!(:batch_student) { FactoryGirl.create(:batch_student, :batch => batch) }
        let!(:subject) { FactoryGirl.create(:subject, :batch => batch, :credit_hours => 1.5) }

        context 'grouped_exams and students are not empty' do
          before do
            @exam_group = FactoryGirl.create(:exam_group, :batch => batch)
            FactoryGirl.create(:grouped_exam, 
              :batch_id => batch.id,
              :exam_group_id => @exam_group.id,
              :weightage => 20)
            FactoryGirl.create(:grouped_exam_report, :batch => batch)
          end

          context 'exam is found' do
            let!(:exam) { FactoryGirl.create(:exam, :exam_group => @exam_group, :subject => subject) }

            context 'grading_type.nil? or normal_enabled?' do
              before { FactoryGirl.create(:exam_score, :exam => exam, :student => batch_student.student, :marks => 60) }

              it 'generate reports' do
                batch.perform
                GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(batch_student.student.id, subject.id, batch.id, 's').marks.should == 12
                GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(batch_student.student.id, @exam_group.id, 'e').marks.should == 60
                GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(batch_student.student.id, batch.id, "c").marks.should == 12
              end
            end

            context 'gpa_enabled?' do
              before do
                Configuration.stub(:has_gpa?).and_return(true)
                batch.course.grading_type = Batch::INVERT_GRADINGTYPES['GPA']
                @grading_level = FactoryGirl.create(:grading_level, :credit_points => 50, :batch => batch)
                FactoryGirl.create(:exam_score,
                  :student => batch_student.student,
                  :exam => exam,
                  :marks => 60,
                  :grading_level => @grading_level)
              end

              it 'generate reports' do
                batch.perform
                GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(batch_student.student.id, subject.id, batch.id, 's').marks.should == 10
                GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(batch_student.student.id, @exam_group.id, 'e').marks.should == 50
                GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(batch_student.student.id, batch.id, "c").marks.should == 10
              end
            end

            context 'cwa_enabled?' do
              before do
                Configuration.stub(:has_cwa?).and_return(true)
                batch.course.grading_type = Batch::INVERT_GRADINGTYPES['CWA']
                @grading_level = FactoryGirl.create(:grading_level, :credit_points => 50, :batch => batch)
                FactoryGirl.create(:exam_score,
                  :student => batch_student.student,
                  :exam => exam,
                  :marks => 70,
                  :grading_level => @grading_level)
              end

              it 'generate reports' do
                batch.perform
                GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(batch_student.student.id, subject.id, batch.id, 's').marks.should == 14
                GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(batch_student.student.id, @exam_group.id, 'e').marks.should == 70
                GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(batch_student.student.id, batch.id, "c").marks.should == 14
              end
            end
          end

          context 'exam is not found' do
            it 'do not generate reports' do
              lambda { batch.perform }.should change(GroupedExamReport, :count).by(0)
            end
          end
        end

        context 'grouped_exams or students are empty' do
          it 'returns nil' do
            lambda { batch.perform }.should change(GroupedExamReport, :count).by(0)
          end
        end
      end
    end

    context 'job_type has other value' do
      describe '#create_scholastic_reports' do
        let(:course) { FactoryGirl.build(:course) }
        let!(:batch) { FactoryGirl.create(:batch, :course => course) }

        context 'assessment_scores is available' do
          before do
            @subject = FactoryGirl.create(:subject, :batch => batch)
            @fa_group = FactoryGirl.create(:fa_group)
            @fa_group.subjects << @subject
            @fa_criteria = FactoryGirl.create(:fa_criteria, :fa_group => @fa_group)
            @des_indicator = FactoryGirl.create(:descriptive_indicator, :describable => @fa_criteria)
            FactoryGirl.create(:assessment_score, 
              :descriptive_indicator => @des_indicator, 
              :batch_id => batch.id,
              :exam_id => 1)
          end

          it 'create scholastic reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(1)
          end
        end

        context 'assessment_scores is unavailable' do
          before do
            @subject = FactoryGirl.create(:subject, :batch => batch)
            @fa_group = FactoryGirl.create(:fa_group)
            @fa_group.subjects << @subject
            @fa_criteria = FactoryGirl.create(:fa_criteria, :fa_group => @fa_group)
            @des_indicator = FactoryGirl.create(:descriptive_indicator, :describable => @fa_criteria)
          end

          it 'do not create reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(0)
          end
        end
      end

      describe '#delete_scholastic_reports' do
        let(:course) { FactoryGirl.build(:course) }
        let(:batch) { FactoryGirl.create(:batch, :course => course) }

        context 'cce_report is found' do
          before do
            FactoryGirl.create(:cce_report)
            FactoryGirl.create(:cce_report, :batch => batch, :exam_id => 12)
          end

          it 'delete scholastic reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(-1)
          end
        end

        context 'cce_report is not found' do
          it 'do not change reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(0)
          end
        end
      end

      describe '#create_coscholastic_reports' do
        let(:course) { FactoryGirl.build(:course) }
        let!(:batch) { FactoryGirl.create(:batch, :course => course) }

        context 'assessment_scores is available' do
          before do
            @cce_grade_set = FactoryGirl.create(:cce_grade_set)
            @obs_group = FactoryGirl.create(:observation_group, :cce_grade_set => @cce_grade_set)
            @obs_group.courses << course
            @observation = FactoryGirl.create(:observation, :observation_group => @obs_group)
            @des_indicator = FactoryGirl.create(:descriptive_indicator, :describable => @observation)
            FactoryGirl.create(:assessment_score, :descriptive_indicator => @des_indicator, :batch_id => batch.id)
          end

          it 'create reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(1)
          end
        end

        context 'assessment_scores is unavailable' do
          before do
            @cce_grade_set = FactoryGirl.create(:cce_grade_set)
            @obs_group = FactoryGirl.create(:observation_group, :cce_grade_set => @cce_grade_set)
            @obs_group.courses << course
            @observation = FactoryGirl.create(:observation, :observation_group => @obs_group)
            @des_indicator = FactoryGirl.create(:descriptive_indicator, :describable => @observation)
          end

          it 'do not create reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(0)
          end
        end
      end

      describe '#delete_coscholastic_reports' do
        let(:course) { FactoryGirl.build(:course) }
        let(:batch) { FactoryGirl.create(:batch, :course => course) }

        context 'cce_report is found' do
          before do
            FactoryGirl.create(:cce_report)
            FactoryGirl.create(:cce_report, :batch => batch)
          end

          it 'delete coscholastic reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(-1)
          end
        end

        context 'cce_report is not found' do
          it 'do not change reports' do
            lambda { batch.perform }.should change(CceReport, :count).by(0)
          end
        end
      end
    end
  end
end
