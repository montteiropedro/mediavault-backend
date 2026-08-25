require 'rails_helper'

RSpec.describe Show, type: :model do
  describe "associations" do
    it { should have_many(:seasons).order(:number).dependent(:destroy) }
    it { should have_many(:episodes).through(:seasons) }
    it { should have_one_attached(:cover_art) }
  end

  describe "validations" do
    subject { build(:show) }

    it { is_expected.to validate_presence_of(:source_path) }
    it { is_expected.to validate_uniqueness_of(:source_path) }
  end
end
