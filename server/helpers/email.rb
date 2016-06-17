module Email
  def h(text)
    Rack::Utils.escape_html text
  end
  def email_password_changed(user)
    Pony.mail(
      to: user.email,
      subject: "Password Was Changed",
      body: "Hi #{h user.username},\nYour password on #{link_to_site_root} was recently changed.\nIf it was you, please ignore this email. If you did not make the change, please file an issue with us on <a href='#{link_to_github}'>Github</a>.\n\n-MagicStick"
    )
    log_debug_email
  end
  #TODO validate email on update/create of user
  def email_password_reset_link(user, link)
    Pony.mail(
      to: user.email,
      subject: "Password Reset Request",
      body: "Hi #{h user.username},\nSomeone requested a reset of your password on #{link_to_site_root}.\nIf it was you, visit the following link to continue: #{link}.\nIf you didn't request this, please ignore this email.\n\n-MagicStick"
    )
    log_debug_email
  end
  def email_user_removed_from_season(season, user, by_user)
    Pony.mail(
      to: user.email,
      subject: "Removed from Season '#{h season.name}'",
      body: "Hi #{h user.username},\nYou were removed from season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.\nIf you think this was done in error, please attempt to contact another members or file an issue with us on <a href='#{link_to_github}'>Github</a>.\n\n-MagicStick"
    )
    log_debug_email
  end
  def email_user_added_to_season(season, user, by_user)
    Pony.mail(
      to: user.email,
      subject: "Added to Season '#{h season.name}'",
      body: "Hi #{h user.username},\nYou were added to season <a href='#{link_to_season season}'><i>#{h season.name}</i></a> by #{h by_user.username}.\nIf you think this was done in error, please visit the page and post a comment or leave the season.\n\n-MagicStick"
    )
    log_debug_email
  end
  def log_debug_email
    return unless settings.development?
    Mail::TestMailer.deliveries.each do |d|
      logger.info "[debug-send] ==========\n#{d.to_s}\n==========\n"
    end
  end
end
