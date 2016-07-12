moment = require 'moment'
btoa = require("btoa")

options =
    hostname: process.env.ANSWERHUB_HOSTNAME or "q.*"
    slack: if process.env.HUBOT_SLACK_TOKEN.length > 0 then true else false
    date_format: 'MMMM Do YYYY, h:mm:ss a'
    bannedUsers: ["q"]

isFoundIn = (term, array) -> array.indexOf(term) isnt -1

make_headers = ->
  user = process.env.ANSWERHUB_USER
  password = process.env.ANSWERHUB_PASSWORD
  auth = btoa("#{user}:#{password}")

  ret =
    Accept: "application/json"
    Authorization: "Basic #{auth}"

author = (msg, authorId, baseUrl, func) ->
    url = "#{baseUrl}/services/v2/user/#{authorId}.json"

    headers = make_headers()
    msg.http(url)
        .headers(headers)
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)
                msg.robot.logger.debug json
                func(json)

            catch error
                msg.robot.logger.debug(error)

getAuthorUrl = (authorId, authorUsername, baseUrl) ->
    return "#{baseUrl}/users/#{authorId}/#{authorUsername}.html"

text = (msg, json, url, baseUrl, func) ->
    author(msg, json.lastActiveUserId, baseUrl, (lastActiveUserJson) ->
        if lastActiveUserJson != undefined
            lastActiveUser = "#{lastActiveUserJson.realname}"
            lastActiveUserUrl = getAuthorUrl(json.lastActiveUserId, lastActiveUserJson.username, baseUrl)
        lastActive = moment.utc(json.lastActiveDate).fromNow()
        authorUrl = getAuthorUrl(json.author.id, json.author.username, baseUrl)

        marked = ""
        if json.marked == false
            marked = "(*none accepted yet!*)"


        topics = json.topics.map (obj) ->
            topicUrl = "#{baseUrl}/topics/#{obj.name}.html"
            return "<#{topicUrl}|#{obj.name}>"
        .join(", ")

        out = "<#{url}|#{json.title}> (#{topics}) by <#{authorUrl}|#{json.author.realname}>\n#{json.upVoteCount} upvotes, "+
               "#{json.answerCount} answers #{marked}"
        if lastActiveUserJson != undefined
            out += "\n_most recent activity by <#{lastActiveUserUrl}|#{lastActiveUser}> #{lastActive}_"

        func(msg, out))

slack_attachment = (msg, text) ->
    try
        msg.robot.emit 'slack.attachment',
            message: msg.message
            content:
                mrkdwn_in: ["pretext"]
                pretext: text
                fallback: text
    catch error
        msg.robot.logger.debug(error)

plain = (msg, text) ->
    try
        msg.send(text)
    catch error
        msg.robot.logger.debug(error)

send_q_msg = (msg, json, url, baseUrl) ->
    if options.slack
        text(msg, json, url, baseUrl, slack_attachment)
    else
        text(msg, json, url, baseUrl, plain)

module.exports = (robot) ->
    robot.hear ///(http|https)://(#{options.hostname})\/questions\/([0-9]+).*html ///i, (msg) ->
        robot.logger.debug msg.message.user

        if isFoundIn(msg.message.user.name, options.bannedUsers)
          return

        headers = make_headers()
        scheme = msg.match[1]
        hostname = msg.match[2]
        id = msg.match[3]
        url = "#{scheme}://#{hostname}/services/v2/question/#{id}.json"
        baseUrl = "#{scheme}://#{hostname}"
        msg.http(url)
        .headers(headers  )
        .get() (err, res, body) ->
            try
                json = JSON.parse(body)
                robot.logger.debug json
                send_q_msg(msg, json, msg.match[0], baseUrl)

            catch error
                msg.robot.logger.debug(error)
