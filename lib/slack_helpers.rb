module SlackHelpers
  def slack_client
    @slack_client ||= Slack::Web::Client.new token: ENV.fetch("SLACK_API_TOKEN") { raise "SLACK_API_TOKEN is not configured!"}
  end

  def post_message(slack_channel, message_text)
    puts message_text if  dry_run?

    slack_client.chat_postMessage(channel: slack_channel, text: message_text, mrkdwn: true) unless dry_run?
  end

  def dry_run?
    ActiveModel::Type::Boolean.new.cast ENV.fetch('DRY_RUN', 'false')
  end

  def post_message_blocks(slack_channel, blocks)
    plain_text = blocks.map do |block|
      case block[:type].to_sym
      when :section
        block[:text][:text].ai
      when :context
        block[:elements].map { |e| e[:text] }.ai(multiline: false)
      when :actions
        block[:elements].map { |e| e[:text][:text] }.ai(multiline: false)
      end
    end.compact.each { |line| puts line if dry_run? }

    slack_client.chat_postMessage(channel: slack_channel, blocks: blocks) unless dry_run?
  end

  def slack_block_section(text)
    { type: "section", text: { type: "mrkdwn", text: text } }
  end

  def slack_block_context(text)
    { type: "context", elements: [ { type: "mrkdwn", text: text } ] }
  end

  def slack_block_actions(actions = [])
    elements = actions.map { |a| { type: "button", url: a[:url], text: { type: "plain_text", text: a[:text], emoji: true } } }
    { type: "actions", elements: elements }
  end
end
