require 'cgi'
module Link
  def link_to_github
    'https://github.com/blaskovicz/MagicStick'
  end

  def link_to_site_root
    (ENV['SITE_BASE_URI'] || '').sub(%r{/$}, '')
  end

  def link_to_reset
    "#{link_to_site_root}/#!/password-reset"
  end

  def link_to_season(season_id)
    id = if season_id.is_a? Season
           season_id.id
         else
           season_id
         end
    "#{link_to_site_root}/#!/seasons/#{id}"
  end

  def link_to_user(username)
    u = if username.is_a? User
          username.username
        else
          username
        end
    "#{link_to_site_root}/#!/users/#{CGI.escape u}"
  end
end
