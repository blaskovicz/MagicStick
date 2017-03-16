require 'logger'
require_relative 'spec_helper'
require_relative '../helpers/logger'

describe 'Logger Helper' do
  include MagicLogger

  context '#logger' do
    it 'should allow logging' do
      expect(respond_to?('logger')).to be true
      expect(logger).to be_kind_of(Logger)
      expect(logger).to equal(logger) # same instance
    end
  end
end
