require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DiscordAgent do
  before(:each) do
    @valid_options = Agents::DiscordAgent.new.default_options
    @checker = Agents::DiscordAgent.new(:name => "DiscordAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
