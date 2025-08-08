class MatchesController < ApplicationController
  def index
    @matches = Match.includes(:players, :match_players).order(started_at: :desc)
  end

  def show
    @match = Match.find(params[:id])
    @statistics = MatchStatistics.new(@match)
  end
end
