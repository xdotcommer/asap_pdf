require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires an email address" do
      user = User.new(password: "password")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it "requires a password" do
      user = User.new(email_address: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  describe "email normalization" do
    it "normalizes email address" do
      user = User.new(email_address: " TEST@EXAMPLE.COM ")
      user.valid?
      expect(user.email_address).to eq("test@example.com")
    end
  end

  describe "associations" do
    it "has many sessions" do
      expect(User.new).to respond_to(:sessions)
    end

    it "destroys associated sessions when destroyed" do
      user = User.create!(email_address: "test@example.com", password: "password")
      user.sessions.create!

      expect { user.destroy }.to change { Session.count }.by(-1)
    end
  end

  describe "authentication" do
    let(:user) { User.create!(email_address: "test@example.com", password: "password") }

    it "authenticates with correct password" do
      expect(user.authenticate("password")).to eq(user)
    end

    it "does not authenticate with incorrect password" do
      expect(user.authenticate("wrong")).to be_falsey
    end
  end
end
