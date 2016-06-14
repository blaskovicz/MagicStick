module Email
  def email_password_changed(user)
    Pony.mail(
      to: user.email,
      subject: "Password Was Changed",
      body: "Hi #{user.username},\nYour password on #{ENV['SITE_BASE_URI']} was recently changed.\nIf it was you, please ignore this email. If you did not make the change, please file an issue with us on github: #{link_to_github}.\n\n-MagicStick"
    )
  end
end
