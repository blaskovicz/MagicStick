angular.module("MagicStick.directives").directive "leaderboard", ->
  scope:
    season: "&"
  restrict: "E"
  templateUrl: "leaderboard-view.html"
  controller: [
    "$scope"
    ($scope) ->
      updateRankings = ->
        return unless angular.isDefined $scope.season()
        rankBucket = {}
        for group in $scope.season().season_match_groups
          for match in group.matches
            for user_season_match in match.user_season_match
              won = user_season_match.won is true
              match_win_count = user_season_match.game_wins ? 0
              username = user_season_match.user_season.user.name
              rankBucket[username] ?= {
                member: user_season_match.user_season.user
                matchWins: 0
                gameWins: 0
              }
              rankBucket[username].gameWins += match_win_count
              rankBucket[username].matchWins += 1 if won
        ranks = _.sortByAll(
          _.values(rankBucket), ['matchWins', 'gameWins']
        ).reverse()
        currentRank = 1
        for rank, i in ranks
          increment = false
          nextRank = ranks[i + 1]
          if not nextRank? or
            nextRank.matchWins != rank.matchWins or
            nextRank.gameWins != rank.gameWins
              increment = true
          rank.rank = currentRank
          currentRank++ if increment
        $scope.rankings = ranks
      $scope.$watch "season()", ->
        updateRankings()
      , true
  ]

