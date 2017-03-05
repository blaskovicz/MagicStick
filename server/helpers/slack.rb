require 'slack-notifier'
require 'httparty'
require 'json'
module Slack
  def slack_escape(message)
    with_notifier do |notifier|
      notifier.escape(message)
    end
  end

  def slack_message(message, extra_options = {})
    extra_options['channel'] = '#api-testing' unless ENV['RACK_ENV'] == 'production'
    message = Slack::Notifier::LinkFormatter.format(message)
    with_notifier do |notifier|
      logger.info("Sending slack message '#{message.gsub(/\n/, '\\n')}' with options #{extra_options.inspect}")
      notifier.ping(message, extra_options)
    end
  end

  def with_notifier
    raise 'SLACK_WEBHOOK_URL unset' unless ENV.key? 'SLACK_WEBHOOK_URL'
    # TODO: exception handling here
    yield Slack::Notifier.new(
      ENV['SLACK_WEBHOOK_URL'],
      username: "magic-stick-notify via #{link_to_site_root}",
      icon_emoji: ':loudspeaker:',
      channel: '#fml'
    )
  end

  def assert_slack_creds
    raise 'SLACK_SUBDOMAIN unset' unless ENV.key? 'SLACK_SUBDOMAIN'
    raise 'SLACK_ADMIN_TOKEN unset' unless ENV.key? 'SLACK_ADMIN_TOKEN'
  end

  def slack_user_list
    assert_slack_creds
    resp = HTTParty.get("https://#{ENV['SLACK_SUBDOMAIN']}.slack.com/api/users.list?token=#{ENV['SLACK_ADMIN_TOKEN']}")
    if resp.success?
      (JSON.parse(resp.body)['members'] || []).map do |m|
        m['profile']['email']
      end
    else
      logger.warn "Failed to get user list from slack: #{resp.code} #{resp.message} - #{resp.body ? resp.body[0, 100] : '<no body>'}..."
      []
    end
  end

  def invite_to_slack(user)
    assert_slack_creds
    return unless ENV['RACK_ENV'] == 'production'
    names = (user.name || '').split(/\s+/)
    begin
      resp = HTTParty.post(
        "https://#{ENV['SLACK_SUBDOMAIN']}.slack.com/api/users.admin.invite", body: {
          token: ENV['SLACK_ADMIN_TOKEN'],
          email: user.email,
          first_name: !names.empty? ? names.first : '',
          last_name: names.length > 1 ? names[1..(names.length - 1)].join(' ') : '',
          set_active: true
        }
      )
      unless resp.success?
        logger.warn "Failed to invite #{user.email} to slack: #{resp.code} #{resp.message} - #{resp.body ? resp.body[0, 100] : '<no body>'}..."
        return
      end
      body = JSON.parse resp.body
      if body['ok']
        logger.info "Invited #{user.email} to slack successfully"
      else
        logger.warn "Failed to invite #{user.email} to slack: #{body['error']}"
      end
    rescue => e
      logger.warn "Caught error inviting #{user.email} to slack: #{e}"
    end
  end

  def in_slack?(user)
    @slack_users ||= slack_user_list
    @slack_users.include? user.email
  end
end
