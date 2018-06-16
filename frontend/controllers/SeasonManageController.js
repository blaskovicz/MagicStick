/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import angular from "angular";
import _ from "lodash";
angular.module("MagicStick.controllers").controller("SeasonManageController", [
  "$scope",
  "User",
  "$http",
  "season",
  "toastr",
  function($scope, User, $http, season, toastr) {
    const getReason = res =>
      ": " +
      (res == null
        ? "Try again later."
        : res.error != null
          ? res.error
          : res.errors != null
            ? res.errors
            : `An error occurred (${res}).`);
    $scope.season = season;
    $scope.comment = {
      comment: "",
      savedComment: ""
    };
    $scope.bestOfOptions = [
      { id: 1, name: "one" },
      { id: 3, name: "three" },
      { id: 5, name: "five" },
      { id: 7, name: "seven" },
      { id: 11, name: "eleven" }
    ];
    $scope.isCurrentUser = user =>
      (user != null ? user.username : undefined) === User.username;
    $scope.userLabel = user =>
      user.username + (user.name != null ? ` (${user.name})` : "");
    $scope.seasonOwner = () =>
      $scope.isCurrentUser(season != null ? season.owner : undefined);
    $scope.seasonParticipant = () =>
      _.find(season != null ? season.members : undefined, {
        username: User.username
      });
    $scope.matchStatusAlias = function(status) {
      if (status === false) {
        return "Loss";
      } else if (status === true) {
        return "Win";
      } else if (status == null) {
        return "Not Played";
      } else {
        return "??";
      }
    };

    $scope.matchIsComplete = match =>
      __guard__(
        match != null ? match.user_season_match : undefined,
        x => x.length
      ) > 0 &&
      _.some(
        match.user_season_match,
        userMatch => (userMatch != null ? userMatch.won : undefined) != null
      );

    $scope.matchGroupIsComplete = group =>
      __guard__(group != null ? group.matches : undefined, x => x.length) > 0 &&
      _.every(group.matches, match => $scope.matchIsComplete(match));

    $scope.updateJoinType = function() {
      if (season == null) {
        return;
      }
      $scope.updatingSeason = true;
      let to = "";
      if (season.invite_only) {
        season.allow_auto_join = false;
        to = "invite only";
      } else {
        season.allow_auto_join = true;
        to = "anyone can join";
      }
      return $http
        .put(`/api/match/seasons/${season.id}/join-mode`, {
          season: {
            invite_only: season.invite_only,
            allow_auto_join: season.allow_auto_join
          }
        })
        .then(() => toastr.success(`Updated join mode to '${to}'`))
        .catch(err =>
          toastr.error(
            `Couldn't update join mode to '${to}': ${getReason(err)}`
          )
        )
        .finally(() => ($scope.updatingSeason = false));
    };
    $scope.createSeasonGrouping = groupingName =>
      $http
        .post(`/api/match/seasons/${season.id}/match-groups`, {
          name: groupingName
        })
        .success(function(newGroup) {
          toastr.success("Grouping successfully created");
          if (newGroup.matches == null) {
            newGroup.matches = [];
          }
          season.season_match_groups.push(newGroup);
          $scope.newGroupingNameError = null;
          return ($scope.newGroupingName = null);
        })
        .error(function(data) {
          let left;
          return ($scope.newGroupingNameError =
            (left =
              __guard__(data != null ? data.errors : undefined, x => x.name) !=
              null
                ? __guard__(data != null ? data.errors : undefined, x => x.name)
                : data != null
                  ? data.errors["[:season_id, :name]"]
                  : undefined) != null
              ? left
              : ["is invalid"]);
        });
    $scope.removeSeasonGrouping = group =>
      $http
        .delete(`/api/match/seasons/${season.id}/match-groups/${group.id}`)
        .success(function() {
          toastr.success("Successfully deleted match group");
          return _.remove(
            season.season_match_groups,
            nextGroup => nextGroup.id === group.id
          );
        })
        .error(reason =>
          toastr.error(
            `Failed to remove season match grouping ${getReason(reason)}`
          )
        );
    $scope.joinSeason = () => $scope.addSeasonMember(User.clone());
    $scope.addSeasonMember = function(newMember) {
      if (_.find(season.members, { username: newMember.username })) {
        $scope.newMember = null;
        toastr.info("User already present in season");
        return;
      }
      const isCurrentUser = $scope.isCurrentUser(newMember);
      return $http
        .put(`/api/match/seasons/${season.id}/members/${newMember.id}`)
        .success(function() {
          if (isCurrentUser) {
            toastr.success("Joined the season");
          } else {
            toastr.success("User added to season");
          }
          season.members.push(newMember);
          return ($scope.newMember = null);
        })
        .error(reason =>
          toastr.error(
            `Failed to add ${newMember.username} to season ${getReason(reason)}`
          )
        );
    };
    $scope.findMembersMatching = text =>
      $http
        .get("/api/auth/users", {
          params: {
            limitted: true,
            matching: text
          }
        })
        .then(response => response.data.users);
    $scope.removeSeasonMember = function(member) {
      const isCurrentUser = $scope.isCurrentUser(member);
      if (
        isCurrentUser &&
        !confirm(`Do you really want to leave the season? \
All of your match records will be deleted.`)
      ) {
        return;
      } else if (
        !isCurrentUser &&
        !confirm(`Do you really want to remove \
${member.username} from the season? \
All of their match records will be deleted.`)
      ) {
        return;
      }
      return $http
        .delete(`/api/match/seasons/${season.id}/members/${member.id}`)
        .success(function() {
          if (isCurrentUser) {
            toastr.success("Left the season");
          } else {
            toastr.success("User removed from the season");
          }
          return _.remove(
            season.members,
            nextMember => nextMember.id === member.id
          );
        })
        .error(function(reason) {
          if (isCurrentUser) {
            return toastr.error(`Failed to leave season ${getReason(reason)}`);
          } else {
            return toastr.error(
              `Failed to remove user ${member.username} from season \
${getReason(reason)}`
            );
          }
        });
    };
    $scope.newMatch = {
      scheduled_for: new Date(),
      best_of: $scope.bestOfOptions[1].id
    };
    $scope.newMatchError = null;
    $scope.createMatch = function() {
      if ($scope.newMatch.season_match_group_id == null) {
        return;
      }
      const newMatchSlug = angular.copy($scope.newMatch);
      return $http
        .post(
          `/api/match/seasons/${season.id}` +
            `/match-groups/${newMatchSlug.season_match_group_id}/matches`,
          {
            match: newMatchSlug
          }
        )
        .success(function(newMatch) {
          toastr.success(`Match ${newMatch.id} successfully created`);
          const group = findGroup(newMatchSlug.season_match_group_id);
          if (group == null) {
            return;
          }
          if (group.matches == null) {
            group.matches = [];
          }
          if (newMatch.user_season_match == null) {
            newMatch.user_season_match = [];
          }
          return group.matches.push(newMatch);
        })
        .error(function(data) {
          toastr.error("Couldn't create match");
          return ($scope.newMatchError = getReason(data));
        });
    };
    $scope.deleteMatch = (groupId, matchId) =>
      $http
        .delete(matchPath(groupId, matchId))
        .success(function() {
          toastr.success(`Match ${matchId} successfully deleted`);
          const group = findGroup(groupId);
          if (group == null) {
            return;
          }
          return _.remove(group.matches, item => item.id === matchId);
        })
        .error(data =>
          toastr.error(`Couldn't delete match: ${getReason(data)}`)
        );
    $scope.addNextMatchMember = function(nextMatchMember, groupId, matchId) {
      const member = angular.copy(nextMatchMember);
      return $http
        .put(`${matchPath(groupId, matchId)}/members/${member.id}`)
        .success(function() {
          toastr.success("Successfully added user to match");
          return refreshMatchMembers(groupId, matchId);
        })
        .error(data =>
          toastr.error(
            "Couldn't add user to match: " +
              (data.errors != null ? JSON.stringify(data.errors) : data)
          )
        );
    };
    $scope.removeMatchMember = (memberId, groupId, matchId) =>
      $http
        .delete(`${matchPath(groupId, matchId)}/members/${memberId}`)
        .success(function() {
          toastr.success("Successfully removed user from match");
          return refreshMatchMembers(groupId, matchId);
        })
        .error(data =>
          toastr.error(`Couldn't remove member from match: ${getReason(data)}`)
        );

    const findMatchMember = function(match) {
      if (
        !(
          __guard__(
            match != null ? match.user_season_match : undefined,
            x => x.length
          ) > 0
        )
      ) {
        return;
      }
      const member = _.find(match.user_season_match, item =>
        $scope.isCurrentUser(item.user_season.user)
      );
      return member;
    };
    $scope.isMatchMember = match => findMatchMember(match) != null;
    $scope.isMatchWinner = match =>
      __guard__(findMatchMember(match), x => x.won) === true;
    $scope.isMatchLoser = match =>
      __guard__(findMatchMember(match), x => x.won) === false;
    $scope.statusIsUpdating = false;
    $scope.updateMatchStatus = function(
      groupId,
      matchId,
      memberId,
      newStatus,
      wins
    ) {
      $scope.statusIsUpdating = true;
      return $http
        .put(`${matchPath(groupId, matchId)}/members/${memberId}/status`, {
          status: newStatus,
          game_wins: parseInt(wins, 10)
        })
        .success(() => refreshMatchMembers(groupId, matchId))
        .error(function(data) {
          $scope.statusIsUpdating = false;
          return toastr.error(
            `Couldn't update member match status: ${
              data.errors != null ? data.errors : data
            }`
          );
        });
    };
    $scope.hasCommentPrivs = comment =>
      $scope.isCurrentUser(comment != null ? comment.user : undefined);
    $scope.deleteComment = comment =>
      $http
        .delete(`/api/match/seasons/${season.id}/comments/${comment.id}`)
        .success(function() {
          toastr.success("Comment successfully deleted");
          return (comment.hidden = true);
        })
        .error(data =>
          toastr.error(
            `Comment couldn't be deleted: ${
              data.errors != null ? data.errors : data
            }`
          )
        );
    //TODO DRY all these up into services
    $scope.addComment = comment =>
      $http
        .post(`/api/match/seasons/${season.id}/comments`, {
          comment: comment.comment
        })
        .success(function(fullComment) {
          toastr.success("Comment successfully created");
          if ($scope.comments == null) {
            $scope.comments = [];
          }
          $scope.comments.push(fullComment.season_comment);
          return ($scope.comment = {
            comment: "",
            savedComment: ""
          });
        })
        .error(function(data) {
          toastr.error("Comment couldn't be created");
          return (comment.error =
            (data.errors != null ? data.errors.comment : undefined) != null
              ? data.errors.comment.join(", ")
              : data);
        });
    $scope.updateComment = function(comment) {
      if (comment.savedComment === comment.comment) {
        return;
      }
      return $http
        .put(`/api/match/seasons/${season.id}/comments/${comment.id}`, {
          comment: comment.comment
        })
        .success(function(newFields) {
          toastr.success("Comment successfully updated");
          comment.updated_at = newFields.season_comment.updated_at;
          return (comment.editMode = false);
        })
        .error(function(data) {
          toastr.error("Couldn't update comment");
          return (comment.error =
            (data.errors != null ? data.errors.comment : undefined) != null
              ? data.errors.comment.join(", ")
              : data);
        });
    };
    $scope.enterEditMode = function(comment) {
      comment.savedComment = comment.comment;
      return (comment.editMode = true);
    };
    $scope.cancelEditMode = function(comment) {
      comment.comment = comment.savedComment;
      return (comment.editMode = false);
    };
    $scope.commentUnchanged = comment =>
      comment.savedComment === comment.comment;
    // reload the members of the match from the api since the json
    // format is non-trivial
    var refreshMatchMembers = function(groupId, matchId) {
      const match = findMatch(groupId, matchId);
      if (match == null) {
        return;
      }
      return $http
        .get(matchPath(groupId, matchId))
        .success(function(matchData) {
          match.user_season_match = matchData.user_season_match;
          return ($scope.statusIsUpdating = false);
        })
        .error(() => ($scope.statusIsUpdating = false));
    };
    var findMatch = function(groupId, matchId) {
      if (matchId == null || groupId == null) {
        return;
      }
      const group = findGroup(groupId);
      if (group == null) {
        return;
      }
      return _.find(group.matches, item => item.id === matchId);
    };
    var findGroup = groupId =>
      _.find(season.season_match_groups, item => item.id === groupId);
    var matchPath = (groupId, matchId) =>
      `/api/match/seasons/${season.id}` +
      `/match-groups/${groupId}/matches/${matchId}`;
    return $http
      .get(`/api/match/seasons/${season.id}/comments`)
      .success(
        comments =>
          ($scope.comments =
            (comments != null ? comments.season_comments : undefined) != null
              ? comments != null
                ? comments.season_comments
                : undefined
              : [])
      );
  }
]);

function __guard__(value, transform) {
  return typeof value !== "undefined" && value !== null
    ? transform(value)
    : undefined;
}
