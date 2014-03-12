require 'json'
require 'rack/request'
require 'slack-notifier'

class App
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

  def failure
    [405, { 'Content-Type' => 'text/plain'}, ['405 Method Not Allowed']]
  end

  def notify_to_slack(request)
    json = JSON.parse(request.body.read)
    project_name = json['project_name']
    message = json['message']
    level = json['level']
    url = json['url']

    text = "[#{level}] #{project_name} - #{message} <a href='#{url}'>View</a>"

    notifier = Slack::Notifier.new(slack_team, slack_token)
    notifier.ping(text, channel: slack_channel)
  end

  def slack_channel
    return ENV['SLACK_CHANNEL'] if ENV['SLACK_CHANNEL'][0] == '#'
    '#' + ENV['SLACK_CHANNEL']
  end

  def slack_team
    ENV['SLACK_TEAM']
  end

  def slack_token
    ENV['SLACK_TOKEN']
  end

  def success
    [200, { 'Content-Type' => 'text/plain'}, ['OK']]
  end

  def valid_request?(request)
    request.post? && request.path == NOTIFY_PATH
  end
end
