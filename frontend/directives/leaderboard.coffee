angular.module("MagicStick.directives").directive "leaderboard", ->
  scope:
    season: "&"
  restrict: "E"
  templateUrl: "leaderboard-view.html"
  controller: [
    "$scope"
    ($scope) ->
      maxOpacity = 0.9
      minOpacity = 0.1
      opacityFor = (rank, maxRanks) ->
        factor = (maxOpacity - minOpacity) / maxRanks
        offset = if rank isnt maxRanks then 1 else 0
        factor * (maxRanks + offset - rank) + minOpacity
      updateRankings = ->
        return unless angular.isDefined $scope.season()
        rankBucket = {}
        for group in $scope.season().season_match_groups
          for match in group.matches
            for user_season_match in match.user_season_match
              match_win_count = user_season_match.game_wins ? 0
              username = user_season_match.user_season.user.name
              rankBucket[username] ?= {
                member: user_season_match.user_season.user
                matchWins: 0
                gameWins: 0
                matchUnplayed: 0
                matchLoss: 0
              }
              incrField = if user_season_match.won is true
                'matchWins'
              else if user_season_match.won is false
                'matchLoss'
              else
                'matchUnplayed'
              rankBucket[username][incrField] += 1
              rankBucket[username].gameWins += match_win_count
        ranks = _.sortByAll(
          _.values(rankBucket), ['matchWins', 'gameWins']
        ).reverse()
        currentRank = 1
        numRanks = ranks.length
        rankGap = 0
        # for every row sorted by matchWins, then gameWins descending,
        # assign them the currentRank. if the next row isn't equivalent
        # in standing, increment the rank by one, accounting for any
        # gaps (ties) (eg: if two people are ranked 1st, the next
        # person would be ranked 3rd).  if the next row is the same
        # rank, increase the rankGap.
        for rank, i in ranks
          increment = false
          nextRank = ranks[i + 1]
          if not nextRank? or
            nextRank.matchWins != rank.matchWins or
            nextRank.gameWins != rank.gameWins
              increment = true
          rank.rank = currentRank
          rank.opacity = opacityFor currentRank, numRanks
          if increment
            currentRank++
            currentRank += rankGap
            rankGap = 0
          else
            rankGap++
        $scope.rankings = ranks
      $scope.$watch "season()", ->
        updateRankings()
      , true
  ]

