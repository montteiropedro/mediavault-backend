require 'rails_helper'

RSpec.describe Season, type: :model do
  describe "associations" do
    it { should belong_to(:show) }
    it { should have_many(:episodes).order(:number).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:season) }

    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_presence_of(:source_path) }
    it { is_expected.to validate_uniqueness_of(:source_path) }
    it { is_expected.to validate_uniqueness_of(:show_id).scoped_to(:number).ignoring_case_sensitivity }
  end
end
