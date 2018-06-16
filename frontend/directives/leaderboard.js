/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
import _ from "lodash";

angular.module("MagicStick.directives").directive("leaderboard", () => ({
  scope: {
    season: "&"
  },
  restrict: "E",
  template: require("../views/leaderboard-view.html"),
  controller: [
    "$scope",
    function($scope) {
      const maxOpacity = 0.9;
      const minOpacity = 0.1;
      const opacityFor = function(rank, maxRanks) {
        const factor = (maxOpacity - minOpacity) / maxRanks;
        const offset = rank !== maxRanks ? 1 : 0;
        return factor * (maxRanks + offset - rank) + minOpacity;
      };
      const updateRankings = function() {
        if (!angular.isDefined($scope.season())) {
          return;
        }
        const rankBucket = {};
        for (let group of Array.from($scope.season().season_match_groups)) {
          for (let match of Array.from(group.matches)) {
            for (let user_season_match of Array.from(match.user_season_match)) {
              const match_win_count =
                user_season_match.game_wins != null
                  ? user_season_match.game_wins
                  : 0;
              const username = user_season_match.user_season.user.name;
              if (rankBucket[username] == null) {
                rankBucket[username] = {
                  member: user_season_match.user_season.user,
                  matchWins: 0,
                  gameWins: 0,
                  matchUnplayed: 0,
                  matchLoss: 0
                };
              }
              const incrField =
                user_season_match.won === true
                  ? "matchWins"
                  : user_season_match.won === false
                    ? "matchLoss"
                    : "matchUnplayed";
              rankBucket[username][incrField] += 1;
              rankBucket[username].gameWins += match_win_count;
            }
          }
        }
        const ranks = _
          .sortByAll(_.values(rankBucket), ["matchWins", "gameWins"])
          .reverse();
        let currentRank = 1;
        const numRanks = ranks.length;
        let rankGap = 0;
        // for every row sorted by matchWins, then gameWins descending,
        // assign them the currentRank. if the next row isn't equivalent
        // in standing, increment the rank by one, accounting for any
        // gaps (ties) (eg: if two people are ranked 1st, the next
        // person would be ranked 3rd).  if the next row is the same
        // rank, increase the rankGap.
        for (let i = 0; i < ranks.length; i++) {
          const rank = ranks[i];
          let increment = false;
          const nextRank = ranks[i + 1];
          if (
            nextRank == null ||
            nextRank.matchWins !== rank.matchWins ||
            nextRank.gameWins !== rank.gameWins
          ) {
            increment = true;
          }
          rank.rank = currentRank;
          rank.opacity = opacityFor(currentRank, numRanks);
          if (increment) {
            currentRank++;
            currentRank += rankGap;
            rankGap = 0;
          } else {
            rankGap++;
          }
        }
        return ($scope.rankings = ranks);
      };
      return $scope.$watch("season()", () => updateRankings(), true);
    }
  ]
}));
