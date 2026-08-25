require 'rails_helper'

RSpec.describe Progress, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:playable) }
  end

  describe "validations" do
    subject { build(:progress) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:playable_type, :playable_id).ignoring_case_sensitivity }
  end
end
