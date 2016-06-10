require 'slack-ruby-client'
require 'logging'
require './monkeylearn.rb'

logger = Logging.logger(STDOUT)
logger.level = :debug

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  if not config.token
    logger.fatal('Missing ENV[SLACK_TOKEN]! Exiting program')
    exit
  end
end

client = Slack::RealTime::Client.new

# listen for hello (connection) event - https://api.slack.com/events/hello
client.on :hello do
  logger.debug("Connected '#{client.self['name']}' to '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com.")
end

# listen for channel_joined event - https://api.slack.com/events/channel_joined
client.on :channel_joined do |data|
  if joiner_is_bot?(client, data)
    client.message channel: data['channel']['id'], text: "Thanks for the invite! I don\'t do much yet, but #{help}"
    logger.debug("#{client.self['name']} joined channel #{data['channel']['id']}")
  else
    logger.debug("Someone far less important than #{client.self['name']} joined #{data['channel']['id']}")
  end
end

traning_mode = false
TRAINING_SAMPLES = Array.new
classifying_mode = false
CLASSIFY_TEXT = Array.new

# listen for message event - https://api.slack.com/events/message
client.on :message do |data|
  if traning_mode then
    case data['text']
    when 'done' then
      traning_mode = false
      client.message channel: data['channel'], text: TRAINING_SAMPLES.to_s
      monkeylearn_train TRAINING_SAMPLES
      logger.debug("#{client.self['name']} parei e mandei treinar")
    else 
      TRAINING_SAMPLES << data['text']
    end
  elsif classifying_mode then
    CLASSIFY_TEXT << data['text']
    client.message channel: data['channel'], text: "#{monkeylearn_classify CLASSIFY_TEXT}"
    logger.debug("#{client.self['name']} postei o resultado")
    CLASSIFY_TEXT = []
    classifying_mode = false
  else
    case data['text']
    when 'Start training'
      traning_mode = true
      TRAINING_SAMPLES = []
      client.message channel: data['channel'], text: "Vai falando, quando acabar digite done."
      logger.debug("#{client.self['name']} comecei a treinar")
    when 'Classify'
      client.message channel: data['channel'], text: "Digite o texto que quer classificar"
      logger.debug("#{client.self['name']} Usuario quer classificar")
      classifying_mode = true
    when 'Olá'
      client.message channel: data['channel'], text: "Olá para você também, <@#{{data['user']}}"
      logger.debug("#{client.self['name']} Olá para o usuário")
    end
  end
  # case data['text']
  # when 'hi', 'bot hi' then
  #   client.typing channel: data['channel']
  #   client.message channel: data['channel'], text: "Hello <@#{data['user']}>."
  #   logger.debug("<@#{data['user']}> said hi")

  #   if direct_message?(data)
  #     client.message channel: data['channel'], text: "It\'s nice to talk to you directly."
  #     logger.debug("And it was a direct message")
  #   end

  # when 'attachment', 'bot attachment' then
  #   # attachment messages require using web_client
  #   client.web_client.chat_postMessage(post_message_payload(data))
  #   logger.debug("Attachment message posted")

  # when bot_mentioned(client)
  #   client.message channel: data['channel'], text: 'You really do care about me. :heart:'
  #   logger.debug("Bot mentioned in channel #{data['channel']}")

  # when 'bot help', 'help' then
  #   client.message channel: data['channel'], text: help
  #   logger.debug("A call for help")

  # when /^bot/ then
  #   client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, I don\'t understand. \n#{help}"
  #   logger.debug("Unknown command")
  # end
end

def direct_message?(data)
  # direct message channles start with a 'D'
  data['channel'][0] == 'D'
end

def bot_mentioned(client)
  # match on any instances of `<@bot_id>` in the message
  /\<\@#{client.self['id']}\>+/
end

def joiner_is_bot?(client, data)
 /^\<\@#{client.self['id']}\>/.match data['channel']['latest']['text']
end

def help
  %Q(I will respond to the following messages: \n
      `bot hi` for a simple message.\n
      `bot attachment` to see a Slack attachment message.\n
      `@<your bot\'s name>` to demonstrate detecting a mention.\n
      `bot help` to see this again.)
end

def post_message_payload(data)
  main_msg = 'Beep Beep Boop is a ridiculously simple hosting platform for your Slackbots.'
  {
    channel: data['channel'],
      as_user: true,
      attachments: [
        {
          fallback: main_msg,
          pretext: 'We bring bots to life. :sunglasses: :thumbsup:',
          title: 'Host, deploy and share your bot in seconds.',
          image_url: 'https://storage.googleapis.com/beepboophq/_assets/bot-1.22f6fb.png',
          title_link: 'https://beepboophq.com/',
          text: main_msg,
          color: '#7CD197'
        }
      ]
  }
end

client.start!
