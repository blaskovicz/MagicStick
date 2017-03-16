require_relative '../spec_helper'
require_relative '../../models/season_comment'

describe 'SeasonComment' do
  context 'validations' do
    it 'should set and check reasonable defaults' do
      comment = SeasonComment.new
      expect(comment).not_to be_valid
      expect(comment.errors[:user_id]).not_to be_nil
      expect(comment.errors[:season_id]).not_to be_nil
      expect(comment.errors[:comment]).not_to be_nil

      comment.comment = 'test words'
      comment.user_id = 98
      comment.season_id = 99
      expect(comment).to be_valid
      expect(comment.errors).to be_empty
    end
  end
end
