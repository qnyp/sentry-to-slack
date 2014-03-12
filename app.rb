require 'json'
require 'rack/request'
require 'slack-notifier'

# Rack application.
class App
  # Endpoint path
  NOTIFY_PATH = '/notify'

  def call(env)
    request = Rack::Request.new(env)
    if valid_request?(request)
      notify_to_slack(request)
      success
    else
      failure
    end
  end

  private

  # Private: Constructs an text message which send to the Slack.
  #
  # Returns a String.
  def build_text(request)
    sentry = sentry_payload(request)
    project_name = sentry['project_name']
    message = sentry['message']
    level = sentry['level']
    url = sentry['url']
    "[#{level}] #{project_name} - #{message} <a href='#{url}'>View</a>"
  end

  # Private: Returns an array which represents failed response.
  #
  # Returns an Array.
  def failure
    [405, { 'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
  end

  # Private: Send a notification message to the Slack channel.
  #
  # request - An instance of Rack::Request.
  #
  # Returns nothing.
  def notify_to_slack(request)
    text = build_text(request)
    notifier = Slack::Notifier.new(slack_team, slack_token)
    notifier.ping(text, channel: slack_channel)
  end

  # Private: Returns a hash which represents a payload sent from the Sentry.
  #
  # request - An instance of Rack::Request.
  #
  # Returns a Hash.
  def sentry_payload(request)
    JSON.parse(request.body.read)
  end

  # Private: Returns a channel name that start with '#'.
  #
  # Returns a String.
  def slack_channel
    return ENV['SLACK_CHANNEL'] if ENV['SLACK_CHANNEL'][0] == '#'
    '#' + ENV['SLACK_CHANNEL']
  end

  # Private: Returns a Slack team identifier.
  #
  # Returns a String.
  def slack_team
    ENV['SLACK_TEAM']
  end

  # Private: Returns a Slack token.
  #
  # Returns a String.
  def slack_token
    ENV['SLACK_TOKEN']
  end

  # Private: Returns an array which represents succeeded response.
  #
  # Returns an Array.
  def success
    [200, { 'Content-Type' => 'text/plain'}, ['OK']]
  end

  # Private: Returns a whether request is valid.
  #
  # request - An instance of Rack::Request.
  #
  # Returns a boolean.
  def valid_request?(request)
    request.post? && request.path == NOTIFY_PATH
  end
end
