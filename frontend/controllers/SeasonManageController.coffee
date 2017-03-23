angular.module("MagicStick.controllers").controller "SeasonManageController", [
  "$scope"
  "User"
  "$http"
  "season"
  "toastr"
  ($scope, User, $http, season, toastr) ->
    getReason = (res) ->
      ": " + unless res?
        "Try again later."
      else if res.error?
        res.error
      else if res.errors?
        res.errors
      else
        "An error occurred (#{res})."
    $scope.season = season
    $scope.comment =
      comment: ""
      savedComment: ""
    $scope.bestOfOptions = [
      {id: 1, name: "one"}
      {id: 3, name: "three"}
      {id: 5, name: "five"}
      {id: 7, name: "seven"}
      {id: 11, name: "eleven"}
    ]
    $scope.isCurrentUser = (user) -> user?.username is User.username
    $scope.userLabel = (user) ->
      user.username + if user.name? then " (#{user.name})" else ""
    $scope.seasonOwner = -> $scope.isCurrentUser(season?.owner)
    $scope.seasonParticipant = ->
      _.find season?.members, {'username': User.username}
    $scope.matchStatusAlias = (status) ->
      if status is false
        "Loss"
      else if status is true
        "Win"
      else if not status?
        "Not Played"
      else
        "??"

    $scope.matchIsComplete = (match) ->
      match?.user_season_match?.length > 0 and \
      _.some match.user_season_match, (userMatch) ->
        userMatch?.won?

    $scope.matchGroupIsComplete = (group) ->
      group?.matches?.length > 0 and \
      _.every group.matches, (match) ->
        $scope.matchIsComplete(match)

    $scope.updateJoinType = ->
      return unless season?
      $scope.updatingSeason = yes
      to = ""
      if season.invite_only
        season.allow_auto_join = no
        to = "invite only"
      else
        season.allow_auto_join = yes
        to = "anyone can join"
      $http.put("/api/match/seasons/#{season.id}/join-mode", {
        season:
          invite_only: season.invite_only
          allow_auto_join: season.allow_auto_join
      }).then (res) ->
          toastr.success "Updated join mode to '#{to}'"
        .catch (err) ->
          toastr.error "Couldn't update join mode to '#{to}': #{getReason err}"
        .finally ->
          $scope.updatingSeason = no
    $scope.createSeasonGrouping = (groupingName) ->
      $http.post("/api/match/seasons/#{season.id}/match-groups", {
        name: groupingName
      }).success (newGroup) ->
          toastr.success "Grouping successfully created"
          newGroup.matches ?= []
          season.season_match_groups.push newGroup
          $scope.newGroupingNameError = null
          $scope.newGroupingName = null
        .error (data) ->
          $scope.newGroupingNameError =
            data?.errors?.name ? \
            data?.errors["[:season_id, :name]"] ? \
            ["is invalid"]
    $scope.removeSeasonGrouping = (group) ->
      $http.delete("/api/match/seasons/#{season.id}/match-groups/#{group.id}")
        .success ->
          toastr.success "Successfully deleted match group"
          _.remove season.season_match_groups,
            (nextGroup) -> nextGroup.id is group.id
        .error (reason) ->
          toastr.error \
            "Failed to remove season match grouping #{getReason reason}"
    $scope.joinSeason = -> $scope.addSeasonMember User.clone()
    $scope.addSeasonMember = (newMember) ->
      if _.find season.members, {'username': newMember.username}
        $scope.newMember = null
        toastr.info "User already present in season"
        return
      isCurrentUser = $scope.isCurrentUser newMember
      $http.put("/api/match/seasons/#{season.id}/members/#{newMember.id}")
        .success ->
          if isCurrentUser
            toastr.success "Joined the season"
          else
            toastr.success "User added to season"
          season.members.push newMember
          $scope.newMember = null
        .error (reason) ->
          toastr.error \
            "Failed to add #{newMember.username} to season #{getReason reason}"
    $scope.findMembersMatching = (text) ->
      $http.get("/api/auth/users", {
        params:
          limitted: true
          matching: text
      }).then (response) -> response.data.users
    $scope.removeSeasonMember = (member) ->
      isCurrentUser = $scope.isCurrentUser member
      if isCurrentUser && (
        !confirm "Do you really want to leave the season? \
        All of your match records will be deleted."
      )
        return
      else if !isCurrentUser && !(confirm "Do you really want to remove \
        #{member.username} from the season? \
        All of their match records will be deleted."
      )
        return
      $http.delete("/api/match/seasons/#{season.id}/members/#{member.id}")
        .success ->
          if isCurrentUser
            toastr.success "Left the season"
          else
            toastr.success "User removed from the season"
          _.remove season.members, (nextMember) -> nextMember.id is member.id
        .error (reason) ->
          if isCurrentUser
            toastr.error "Failed to leave season #{getReason reason}"
          else
            toastr.error \
              "Failed to remove user #{member.username} from season \
              #{getReason reason}"
    $scope.newMatch =
      scheduled_for: new Date()
      best_of: $scope.bestOfOptions[1].id
    $scope.newMatchError = null
    $scope.createMatch = ->
      return unless $scope.newMatch.season_match_group_id?
      newMatchSlug = angular.copy $scope.newMatch
      $http.post("/api/match/seasons/#{season.id}" + \
        "/match-groups/#{newMatchSlug.season_match_group_id}/matches", {
          match: newMatchSlug
      }).success (newMatch) ->
          toastr.success "Match #{newMatch.id} successfully created"
          group = findGroup newMatchSlug.season_match_group_id
          return unless group?
          group.matches ?= []
          newMatch.user_season_match ?= []
          group.matches.push newMatch
        .error (data) ->
          toastr.error "Couldn't create match"
          $scope.newMatchError = getReason data
    $scope.deleteMatch = (groupId, matchId) ->
      $http.delete(matchPath(groupId, matchId))
        .success ->
          toastr.success "Match #{matchId} successfully deleted"
          group = findGroup groupId
          return unless group?
          _.remove group.matches, ((item) -> item.id is matchId)
        .error (data) ->
          toastr.error "Couldn't delete match: #{getReason data}"
    $scope.addNextMatchMember = (nextMatchMember, groupId, matchId) ->
      member = angular.copy nextMatchMember
      $http.put("#{matchPath(groupId, matchId)}/members/#{member.id}")
        .success ->
          toastr.success "Successfully added user to match"
          refreshMatchMembers groupId, matchId
        .error (data) ->
          toastr.error "Couldn't add user to match: " + \
            if data.errors? then JSON.stringify(data.errors) else data
    $scope.removeMatchMember = (memberId, groupId, matchId) ->
      $http.delete("#{matchPath(groupId, matchId)}/members/#{memberId}")
        .success ->
          toastr.success "Successfully removed user from match"
          refreshMatchMembers groupId, matchId
        .error (data) ->
          toastr.error \
            "Couldn't remove member from match: #{getReason data}"

    findMatchMember = (match) ->
      return unless match?.user_season_match?.length > 0
      member = _.find(
        match.user_season_match,
        ((item) -> $scope.isCurrentUser(item.user_season.user))
      )
      member
    $scope.isMatchMember = (match) ->
      findMatchMember(match)?
    $scope.isMatchWinner = (match) ->
      findMatchMember(match)?.won is true
    $scope.isMatchLoser = (match) ->
      findMatchMember(match)?.won is false
    $scope.statusIsUpdating = false
    $scope.updateMatchStatus = (groupId, matchId, memberId, newStatus, wins) ->
      $scope.statusIsUpdating = true
      $http.put("#{matchPath(groupId, matchId)}/members/#{memberId}/status", {
        status: newStatus,
        game_wins: parseInt(wins, 10)
      }).success ->
          refreshMatchMembers groupId, matchId
        .error (data) ->
          $scope.statusIsUpdating = false
          toastr.error \
            "Couldn't update member match status: #{data.errors ? data}"
    $scope.hasCommentPrivs = (comment) -> $scope.isCurrentUser comment?.user
    $scope.deleteComment = (comment) ->
      $http.delete("/api/match/seasons/#{season.id}/comments/#{comment.id}")
        .success ->
          toastr.success "Comment successfully deleted"
          comment.hidden = true
        .error (data) ->
          toastr.error "Comment couldn't be deleted: #{data.errors ? data}"
    #TODO DRY all these up into services
    $scope.addComment = (comment) ->
      $http.post("/api/match/seasons/#{season.id}/comments", {
        comment: comment.comment
      })
        .success (fullComment) ->
          toastr.success "Comment successfully created"
          $scope.comments ?= []
          $scope.comments.push fullComment.season_comment
          $scope.comment =
            comment: ""
            savedComment: ""
        .error (data) ->
          toastr.error "Comment couldn't be created"
          comment.error = if data.errors?.comment?
            data.errors.comment.join(", ")
          else
            data
    $scope.updateComment = (comment) ->
      return if comment.savedComment is comment.comment
      $http.put("/api/match/seasons/#{season.id}/comments/#{comment.id}", {
        comment: comment.comment
      }).success (newFields) ->
          toastr.success "Comment successfully updated"
          comment.updated_at = newFields.season_comment.updated_at
          comment.editMode = false
        .error (data) ->
          toastr.error "Couldn't update comment"
          comment.error = if data.errors?.comment?
            data.errors.comment.join(", ")
          else
            data
    $scope.enterEditMode = (comment) ->
      comment.savedComment = comment.comment
      comment.editMode = true
    $scope.cancelEditMode = (comment) ->
      comment.comment = comment.savedComment
      comment.editMode = false
    $scope.commentUnchanged = (comment) ->
      comment.savedComment is comment.comment
    # reload the members of the match from the api since the json
    # format is non-trivial
    refreshMatchMembers = (groupId, matchId) ->
      match = findMatch groupId, matchId
      return unless match?
      $http.get(matchPath(groupId, matchId))
        .success (matchData) ->
          match.user_season_match = matchData.user_season_match
          $scope.statusIsUpdating = false
        .error ->
          $scope.statusIsUpdating = false
    findMatch = (groupId, matchId) ->
      return unless matchId? and groupId?
      group = findGroup groupId
      return unless group?
      _.find(group.matches, ((item) -> item.id is matchId))
    findGroup = (groupId) ->
      _.find(
        season.season_match_groups,
        ((item) -> item.id is groupId)
      )
    matchPath = (groupId, matchId) ->
      "/api/match/seasons/#{season.id}"+ \
      "/match-groups/#{groupId}/matches/#{matchId}"
    $http.get("/api/match/seasons/#{season.id}/comments")
      .success (comments) ->
        $scope.comments = comments?.season_comments ? []
]
