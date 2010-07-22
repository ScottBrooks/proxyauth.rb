require 'rubygems'
require 'mq'
require 'json'
require 'yaml'

def send_reply(reply, reply_to)
  MQ.direct("").publish(reply.to_json, :key=>reply_to)
end

def handle_login(data)
  user = USERS["users"][data["user"]]
  if user and user["password"] == data["pass"]
    puts "Allowing #{data["user"]} to login"
    {"code"=>200}
  else
    puts "Denying #{data["user"]} to login"
    {"code"=>403}
  end
end

def handle_vhost(data)
  user = USERS["users"][data["user"]]
  if user and user["vhosts"].include?(data["vhost"])
    puts "Allowing #{data["user"]} to access vhost #{data["vhost"]}"
    {"code"=>200}
  else
    puts "Denying #{data["user"]} to access vhost #{data["vhost"]}"
    {"code"=>403}
  end
end

def handle_resource_access(data)
  user = USERS["users"][data["user"]]
  if user and user["queues"][data["item"]] and user["queues"][data["item"]].include?(data["permission"])
    puts "Allowing #{data["user"]} to #{data["permission"]} #{data["item"]}"
    {"code"=>200}
  else
    puts "Denying #{data["user"]} to #{data["permission"]} #{data["item"]}"
    {"code"=>403}
  end
end

def handle(data, reply_to)
  reply = case data["action"]
    when "login"
      handle_login(data)
    when "vhost"
      handle_vhost(data)
    when "resource_access"
      handle_resource_access(data)
  end
  send_reply(reply.merge({"id"=>data["id"]}), reply_to)
end

USERS = YAML.load_file('users.yml')

AMQP.start() do
  puts "Connected"
  MQ.queue('', :auto_delete=>true).bind('proxyauth', :key=>'#').subscribe do |header,msg|
    data = JSON.parse(msg)
    handle(data, header.reply_to)
  end
end
