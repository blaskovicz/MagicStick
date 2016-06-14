require 'cgi'
module Link
  def link_to_github
    "https://github.com/blaskovicz/MagicStick"
  end
  def link_to_site_root
    ENV['SITE_BASE_URI'].sub(/\/$/,"")
  end
  def link_to_reset
    "#{link_to_site_root}/#!/password-reset"
  end
  def link_to_season(season_id)
    "#{link_to_site_root}/#!/seasons/#{season_id}"
  end
  def link_to_user(username)
    "#{link_to_site_root}/#!/users/#{CGI.escape username}"
  end
end
