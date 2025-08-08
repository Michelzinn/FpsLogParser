class RankingsController < ApplicationController
  def index
    @rankings = GlobalStatistics.new.global_rankings
  end
end
