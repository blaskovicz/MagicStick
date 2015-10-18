require 'slack-notifier'
module Slack
  def slack_escape(message)
    with_notifier do |notifier|
      notifier.escape(message)
    end
  end
  def slack_message(message, extra_options={})
    extra_options['channel'] = '#api-testing' unless ENV['RACK_ENV'] == 'production'
    message = Slack::Notifier::LinkFormatter.format(message)
    with_notifier do |notifier|
      logger.info("Sending slack message '#{message.gsub(/\n/,"\\n")}' with options #{extra_options.inspect}")
      notifier.ping(message, extra_options)
    end
  end
  def with_notifier
    return unless ENV.has_key? 'SLACK_WEBHOOK_URL'
    # TODO exception handling here
    yield Slack::Notifier.new(
      ENV['SLACK_WEBHOOK_URL'],
      username: "magic-stick-notify via #{link_to_site_root}",
      icon_emoji: ":loudspeaker:",
      channel: "#fml"
    )
  end
end
