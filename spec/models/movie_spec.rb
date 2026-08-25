require 'rails_helper'

RSpec.describe Movie, type: :model do
  describe "associations" do
    it { should have_one_attached(:cover_art) }
  end

  describe "validations" do
    subject { build(:movie) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:file_path) }
    it { is_expected.to validate_uniqueness_of(:file_path) }
  end
end
