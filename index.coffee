moment = require 'moment'
btoa = require("btoa")

options =
    hostname: process.env.ANSWERHUB_HOSTNAME or "q.*"
    slack: if process.env.HUBOT_SLACK_TOKEN.length > 0 then true else false
    date_format: 'MMMM Do YYYY, h:mm:ss a'


make_headers = ->
  user = process.env.ANSWERHUB_USER
  password = process.env.ANSWERHUB_PASSWORD
  auth = btoa("#{user}:#{password}")

  ret =
    Accept: "application/json"
    Authorization: "Basic #{auth}"

slack_attachement = (msg, hostname, json, url) ->
    try
        topics = json.topics.map (obj) ->
          return obj.name
        .join(", ")

        fields = [
            {
                title: "Question",
                value: "<#{url}|#{json.title}>",
                short: "false"
            },
            {
                title: "Topics",
                value: "#{topics}",
                short: "true"
            },
            {
                title: "Author",
                value: "#{json.author.username}",
                short: "true"
            },
            {
                title: "Created Date",
                value: moment.utc(json.creationDate).format(options.date_format),
                short: "true"
            }
        ]

        msg.robot.emit 'slack.attachment',
            message: msg.message
            content:
                mrkdwn_in: ["text", "fields", "author_name"]
                color: "#3B73B9"
                author_name: "Q"
                author_link: "#{url}"
                author_icon: "https://#{hostname}/themes/base/images/teamhub-logo.png"
                text: ""
                fields: fields
                fallback: plain_msg(msg, hostname, json)


    catch error
        msg.robot.logger.debug(error)

plain_msg = (msg, hostname, json) ->
    topics = json.topics.map (obj) ->
      return obj.name
    .join(", ")

    message = "Question: #{json.title}\n" +
            "Topics: #{topics}\n" +
            "Author: #{json.author.username}\n" +
            "Created Date: " + moment.utc(json.creationDate).format(options.date_format) + "\n"

    return message

plain = (msg, hostname, json) ->
    try
        msg.send(plain_msg(msg, hostname, json))
    catch error
        msg.robot.logger.debug(error)

send_q_msg = (msg, hostname, json, url) ->
    if options.slack
        slack_attachement(msg, hostname, json, url)
    else
        plain(msg, hostname, json)

module.exports = (robot) ->
    robot.hear ///(http|https)://(#{options.hostname})\/questions\/([0-9]+).*html ///i, (msg) ->
        headers = make_headers()
        scheme = msg.match[1]
        hostname = msg.match[2]
        id = msg.match[3]
        url = "#{scheme}://#{hostname}/services/v2/question/#{id}.json"
        msg.http(url)
        .headers(headers  )
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)
                robot.logger.debug json
                send_q_msg(msg, hostname, json, msg.match[0])

            catch error
                msg.robot.logger.debug(error)
