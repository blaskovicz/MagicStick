require_relative '../spec_helper'
require_relative '../../helpers/email'
require_relative '../../helpers/logger'
require_relative '../../helpers/link'

describe 'Email Helper' do
  include Email
  include MagicLogger
  include Link
  attr_reader :settings

  before(:all) do
    @owner = User.new(
      username: 'owner_email_spec_tests_user',
      password: 'test-password',
      email: 'owner_email_spec_tests_user@magic-stick.herokuapp.com',
      name: 'owner_email specuser'
    )
    @owner.save
    @season = Season.new(
      name: 'email_spec_tests',
      description: 'sweet season',
      invite_only: true,
      owner: @owner,
      starts: Time.now,
      ends: (Time.now + 10_000)
    )
    @user = User.new(
      username: 'email_spec_tests_user',
      password: 'test-password',
      email: 'email_spec_tests_user@magic-stick.herokuapp.com',
      name: 'email specuser'
    )
    raise 'failed to save user' unless @user.save
    raise 'failed to save season' unless @season.save
    @comment = SeasonComment.new(
      season: @season,
      comment: 'hey, what is up?',
      user: @owner
    )
    raise 'failed to save comment' unless @comment.save
    @season.add_member @user
  end

  before(:each) do
    @settings = double('settings')
    Mail::TestMailer.deliveries.clear
    expect(delivery_count).to eq(0)
  end

  def delivery_count
    Mail::TestMailer.deliveries.count
  end

  def deliveries
    Mail::TestMailer.deliveries.map(&:to).flatten
  end

  def expect_settings_check
    expect(settings).to receive(:development?).and_return(false)
    expect(settings).to receive(:test?).and_return(true)
  end

  context 'can send' do
    it 'member add' do
      expect_settings_check
      email_user_added_to_season(@season, @user, @owner)
      expect(delivery_count).to eq(2)
      expect(deliveries).to include(@user.email, @season.owner.email)
    end
    it 'member remove' do
      expect_settings_check
      email_user_removed_from_season(@season, @user, @owner)
      expect(delivery_count).to eq(2)
      expect(deliveries).to include(@user.email, @season.owner.email)
    end
    it 'password reset' do
      expect_settings_check
      email_password_reset_link(@user, 'http://some/link')
      expect(delivery_count).to eq(1)
      expect(deliveries).to include(@user.email)
    end
    it 'password changed' do
      expect_settings_check
      email_password_changed(@user)
      expect(delivery_count).to eq(1)
      expect(deliveries).to include(@user.email)
    end
    it 'season comment' do
      expect_settings_check
      email_season_comment(@season, @comment, @comment.user)
      expect(delivery_count).to eq(2)
      expect(deliveries).to include(@comment.user.email, *@season.members.map(&:email))
    end
  end
end
