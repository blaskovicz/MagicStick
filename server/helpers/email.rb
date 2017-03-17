module Email
  def h(text)
    Rack::Utils.escape_html text
  end

  def email_password_changed(user)
    logger.info "[email] notifying #{user.email} about password changed"
    Pony.mail(
      to: user.email,
      subject: 'Password Was Changed',
      headers: { 'X-SMTPAPI' => '2695' },
      html_body: "Hi #{h user.username},\nYour password on #{link_to_site_root} was recently changed.\nIf it was you, please ignore this email. If you did not make the change, please file an issue with us on <a href='#{link_to_github}'>Github</a>.\n\n-MagicStick"
    )
    log_debug_email
  end

  def email_season_comment(season, comment, by_user)
    users = {}
    season.members.each_with_object(users) do |m, o|
      o[m.email] ||= 'are season member'
    end
    season.season_comments.each_with_object(users) do |c, o|
      next if c.hidden
      o[c.user.email] ||= 'commented on season'
    end
    users.each do |email, reason|
      logger.info "[email] notifying #{email} about #{season.id} (#{season.name}) comment #{comment.id}"
      Pony.mail(
        to: email,
        from: "#{h by_user.username} <noreply@magic-stick.herokuapp.com>",
        subject: "[Comment] Season '#{h season.name}'",
        headers: { 'X-SMTPAPI' => '2697' },
        html_body: "#{::MarkdownService.render(comment.comment)}\n\n---\n<i>Reply to this comment by visiting <a href='#{link_to_season season}'>the season page</a></i>.\n<i>You're receiving this email because you #{reason}. If you think this is an error, please <a href='#{link_to_github}'>file an issue</a>.</i>\n"
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
      html_body: "Hi #{h user.username},\nSomeone requested a reset of your password on #{link_to_site_root}.\nIf it was you, visit the following link to continue: #{link}.\nIf you didn't request this, please ignore this email.\n\n-MagicStick"
    )
    log_debug_email
  end

  def email_user_removed_from_season(season, user, by_user)
    logger.info "[email] notifying #{user.email} about #{season.id} (#{season.name}) removal by #{by_user.email}"
    Pony.mail(
      to: user.email,
      subject: "Removed from Season '#{h season.name}'",
      headers: { 'X-SMTPAPI' => '2699' },
      html_body: "Hi #{h user.username},\nYou were removed from season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.\nIf you think this was done in error, please attempt to contact another members or file an issue with us on <a href='#{link_to_github}'>Github</a>.\n\n-MagicStick"
    )
    logger.info "[email] notifying #{season.owner.email} about #{season.id} (#{season.name}) removal of #{user.email} by #{by_user.email}"
    Pony.mail(
      to: season.owner.email,
      subject: "'#{h user.username}' Left Season '#{h season.name}'",
      headers: { 'X-SMTPAPI' => '2699' },
      html_body: "Hi #{h season.owner.username},\n#{h user.username} was just removed from season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.\nIf you think this was done in error, please visit the site and re-add them.\n\n-MagicStick"
    )
    log_debug_email
  end

  def email_user_added_to_season(season, user, by_user)
    logger.info "[email] notifying #{user.email} about #{season.id} (#{season.name}) addition by #{by_user.email}"
    Pony.mail(
      to: user.email,
      subject: "Added to Season '#{h season.name}'",
      headers: { 'X-SMTPAPI' => '2699' },
      html_body: "Hi #{h user.username},\nYou were added to season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.\nIf you think this was done in error, please visit the page and post a comment, or leave the season.\n\n-MagicStick"
    )
    logger.info "[email] notifying #{season.owner.email} about #{season.id} (#{season.name}) addition of #{user.email} by #{by_user.email}"
    Pony.mail(
      to: season.owner.email,
      subject: "'#{h user.username}' Joined Season '#{h season.name}'",
      headers: { 'X-SMTPAPI' => '2699' },
      html_body: "Hi #{h season.owner.username},\n#{h user.username} just was added to season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.\nIf you think this was done in error, please visit the site and remove them.\n\n-MagicStick"
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
