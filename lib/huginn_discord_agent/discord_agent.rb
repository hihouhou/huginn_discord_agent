module Agents
  class DiscordAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!

    description <<-MD
      The Discord Agent interacts with Discord API for sending message for example.

      The `type` can be like sending a message.

      The `content` is needed for sending a message.

      The `channel_id` is needed for sending a message to a specific channel.

      The `emit_events` can create event if wanted.

      The `bot_token` is needed for the authentication.

      The `debug` can add verbosity.

      Set `expected_update_period_in_days` to the maximum amount of time that you'd expect to pass between Events being created by this Agent.

    MD


    event_description <<-MD
      Events look like this:

          {
            "id": "XXXXXXXXXXXXXXXXXXX",
            "type": 0,
            "content": "XXXXXXXXXXXXXXXXXX",
            "channel_id": "XXXXXXXXXXXXXXXXXX",
            "author": {
              "id": "XXXXXXXXXXXXXXXXXX",
              "username": "XXXXXX",
              "avatar": null,
              "avatar_decoration": null,
              "discriminator": "XXXX",
              "public_flags": 0,
              "bot": true
            },
            "attachments": [],
            "embeds": [],
            "mentions": [],
            "mention_roles": [],
            "pinned": false,
            "mention_everyone": false,
            "tts": false,
            "timestamp": "2023-01-11T13:53:48.308000+00:00",
            "edited_timestamp": null,
            "flags": 0,
            "components": [],
            "referenced_message": null
          }
    MD

    def default_options
      {
        'content' => '',
        'type' => 'send_message',
        'bot_token' => '',
        'debug' => 'false',
        'channel_id' => '',
        'emit_events' => 'true',
        'expected_receive_period_in_days' => '7'
      }
    end

    form_configurable :content, type: :string
    form_configurable :type, type: :array, values: ['send_message']
    form_configurable :bot_token, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :channel_id, type: :string
    form_configurable :emit_events, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string

    def validate_options
      errors.add(:base, "type has invalid value: should be 'send_message'") if interpolated['type'].present? && !%w(send_message).include?(interpolated['type'])

      unless options['channel_id'].present? || !['send_message'].include?(options['type'])
        errors.add(:base, "channel_id is a required field")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      unless options['content'].present? || !['send_message'].include?(options['type'])
        errors.add(:base, "content is a required field")
      end

      unless options['bot_token'].present? || !['send_message'].include?(options['type'])
        errors.add(:base, "bot_token is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          trigger_action
        end
      end
    end

    def check
      trigger_action
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "body"
        log body
      end

    end

    def send_message()

      message = { content: interpolated['content'] }.to_json
      
      # Build the HTTP request to send the message
      uri = URI("https://discordapp.com/api/v6/channels/#{interpolated['channel_id']}/messages")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req['Authorization'] = "Bot #{interpolated['bot_token']}"
      req.body = message
      
      # Send the request and print the response
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      log_curl_output(response.code,response.body)

      if interpolated['emit_events'] == 'true'
        create_event payload: response.body
      end

    end

    def trigger_action

      case interpolated['type']
      when "send_message"
        send_message()
      else
        log "Error: type has an invalid value (#{type})"
      end
    end
  end
end
