require 'rubygems'
require 'mq'

AMQP.start(:user=>'test', :pass=>'omg') do
  puts "Connected"
  queue = MQ.queue('messages')
  queue.subscribe do |msg|
    puts msg
  end

end
