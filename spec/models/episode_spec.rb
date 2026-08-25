require 'rails_helper'

RSpec.describe Episode, type: :model do
  describe "associations" do
    it { should belong_to(:season) }
    it { should have_one_attached(:thumbnail) }
  end

  describe "validations" do
    subject { build(:episode) }

    it { is_expected.to validate_presence_of(:file_path) }
    it { is_expected.to validate_uniqueness_of(:file_path) }
    it { is_expected.to validate_uniqueness_of(:season_id).scoped_to(:number).ignoring_case_sensitivity }
  end
end
