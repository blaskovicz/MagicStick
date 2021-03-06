module Email
  def h(text)
    Rack::Utils.escape_html text
  end

  def email_welcome(user, password: nil)
    logger.info "[email] notifying #{user.email} about new account"
    Pony.mail(
      to: user.email,
      subject: 'Welcome to MagicStick',
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2695 }.to_json },
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>Your account just got created on #{link_to_site_root}.</p>
      #{password.nil? ? '' : "<p>You password was set to <b>#{h password}</b> - we recommend you change it immediately.</p>"}
      <p>Why not log in and create or join a season?</p>
      <p>If you think you recieved this email in error, please file an issue with us on <a href='#{link_to_github}'>Github</a>.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def email_password_changed(user)
    logger.info "[email] notifying #{user.email} about password changed"
    Pony.mail(
      to: user.email,
      subject: 'Password Was Changed',
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2695 }.to_json },
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>Your password on #{link_to_site_root} was recently changed.</p>
      <p>If it was you, please ignore this email.</p>
      <p>If you did not make the change, please file an issue with us on <a href='#{link_to_github}'>Github</a>.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def email_season_comment(season, comment, by_user)
    users = {}
    users[season.owner.email] = 'are the season owner'
    season.members.each_with_object(users) do |m, o|
      o[m.email] ||= 'are a season member'
    end
    season.season_comments.each_with_object(users) do |c, o|
      next if c.hidden
      o[c.user.email] ||= 'commented on the season'
    end
    users.each do |email, reason|
      logger.info "[email] notifying #{email} about season #{season.id} (#{season.name}) comment #{comment.id}"
      Pony.mail(
        to: email,
        from: "#{h by_user.username} <noreply@magic-stick.herokuapp.com>",
        subject: "[Comment] Season '#{season.name}'",
        headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2697 }.to_json },
        html_body: "#{::MarkdownService.render(comment.comment)}
        <br/>
        <br/>
        <p>---</p>
        <p><i>Reply to this comment by visiting <a href='#{link_to_season season}'>the season page</a></i>.</p>
        <p><i>You're receiving this email because you #{reason}. If you think this is an error, please <a href='#{link_to_github}'>file an issue</a>.</i></p>"
      )
    end
    log_debug_email
  end

  # TODO: validate email on update/create of user
  def email_password_reset_link(user, link)
    logger.info "[email] notifying #{user.email} about generated password reset link"
    Pony.mail(
      to: user.email,
      subject: 'Password Reset Request',
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>Someone requested a reset of your password on #{link_to_site_root}.</p>
      <p>If it was you, visit the following link to continue: #{link}.</p>
      <p>If you didn't request this, please ignore this email.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def email_user_added_to_match(match, user, by_user)
    logger.info "[email] notifying #{user.email} about match #{match.id} (#{match.title}) addition by #{by_user.email}"
    Pony.mail(
      to: user.email,
      subject: "Added to Match '#{match.title}'",
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2711 }.to_json },
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>You were added to match <a href='#{link_to_season match.season_match_group.season}'><i>#{h match.title}</i></a> by #{h by_user.username}.</p>
      <p>If you think this was done in error, please visit the page and post a comment, or leave the match.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def email_user_removed_from_match(match, user, by_user)
    logger.info "[email] notifying #{user.email} about match #{match.id} (#{match.title}) removal by #{by_user.email}"
    Pony.mail(
      to: user.email,
      subject: "Removed from Match '#{match.title}'",
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2711 }.to_json },
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>You were removed from match <a href='#{link_to_season match.season_match_group.season}'><i>#{h match.title}</i></a> by #{h by_user.username}.</p>
      <p>If you think this was done in error, please attempt to contact another season member or file an issue with us on <a href='#{link_to_github}'>Github</a>.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def email_match_status_updated(match, by_user)
    match_body = ''
    match.user_season_match.each do |usm|
      won_status = if usm.won.nil?
                     'Incomplete'
                   elsif usm.won
                     'Win'
                   else
                     'Loss'
                   end
      match_body += "<tr><td>#{h usm.user.username}</td><td>#{usm.game_wins}</td><td>#{won_status}</td></tr>\n"
    end

    match.user_season_match.each do |usm|
      user = usm.user
      logger.info "[email] notifying #{user.email} about match #{match.id} (#{match.title}) status update by #{by_user.email}"
      Pony.mail(
        to: user.email,
        subject: "Match '#{match.title}' Status Updated",
        headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2715 }.to_json },
        html_body: "<p>Hi #{h user.username},</p>
        <br/>
        <p>The status of your match, <a href='#{link_to_season match.season_match_group.season}'><i>#{h match.title}</i></a>, was just updated by #{h by_user.username}:</p>
        <table>
          <thead>
            <tr><th>User</th><th>Games Won</th><th>Overall Status</th></tr>
          </thead>
          <tbody>
            #{match_body}
          </tbody>
        </table>
        <br/>
        <p>If you think this was done in error, navigate to the season page and update your status or leave a comment.</p>
        <br/>
        <p>-MagicStick</p>"
      )
    end
    log_debug_email
  end

  def email_user_removed_from_season(season, user, by_user)
    logger.info "[email] notifying #{user.email} about season #{season.id} (#{season.name}) removal by #{by_user.email}"
    Pony.mail(
      to: user.email,
      subject: "Removed from Season '#{season.name}'",
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2699 }.to_json },
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>You were removed from season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.</p>
      <p>If you think this was done in error, please attempt to contact another season member or file an issue with us on <a href='#{link_to_github}'>Github</a>.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    logger.info "[email] notifying #{season.owner.email} about season #{season.id} (#{season.name}) removal of #{user.email} by #{by_user.email}"
    Pony.mail(
      to: season.owner.email,
      subject: "'#{user.username}' Left Season '#{season.name}'",
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2699 }.to_json },
      html_body: "<p>Hi #{h season.owner.username},</p>
      <br/>
      <p>#{h user.username} was just removed from season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.</p>
      <p>If you think this was done in error, please visit the site and re-add them.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def email_user_added_to_season(season, user, by_user)
    logger.info "[email] notifying #{user.email} about season #{season.id} (#{season.name}) addition by #{by_user.email}"
    Pony.mail(
      to: user.email,
      subject: "Added to Season '#{season.name}'",
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2699 }.to_json },
      html_body: "<p>Hi #{h user.username},</p>
      <br/>
      <p>You were added to season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.</p>
      <p>If you think this was done in error, please visit the page and post a comment, or leave the season.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    logger.info "[email] notifying #{season.owner.email} about season #{season.id} (#{season.name}) addition of #{user.email} by #{by_user.email}"
    Pony.mail(
      to: season.owner.email,
      subject: "'#{user.username}' Joined Season '#{season.name}'",
      headers: { 'X-SMTPAPI' => { 'asm_group_id' => 2699 }.to_json },
      html_body: "<p>Hi #{h season.owner.username},</p>
      <br/>
      <p>#{h user.username} just was added to season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.</p>
      <p>If you think this was done in error, please visit the site and remove them.</p>
      <br/>
      <p>-MagicStick</p>"
    )
    log_debug_email
  end

  def log_debug_email
    return unless settings.development? || settings.test?
    Mail::TestMailer.deliveries.each do |d|
      logger.info "[debug-send] ==========\n#{d}\n==========\n"
    end
  end
end
