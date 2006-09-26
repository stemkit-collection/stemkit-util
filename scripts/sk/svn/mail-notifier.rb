# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'net/smtp'
require 'tsc/contrib/mailfactory.rb'
require 'sk/svn/look.rb'

module SK
  module Svn
    class MailNotifier
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def process(info)
        notification_list = config.notify(info.depot)
        return if notification_list.empty?

        mail = MailFactory.new

        mail.subject = "SVN[#{info.depot}] #{info.revision}: #{info.log.to_s.map.first[0...70]}"
        mail.from = "#{info.author}@#{config.domain}"
        mail.to = notification_list
        mail.text = [ info.digest(config.url_base), info.diff ].flatten.join("\n")

        Net::SMTP.start('127.0.0.1', 25, config.domain) { |smtp|
          smtp.send_message(mail.to_s(), mail.from, mail.to)
        }
        $stderr.puts "Notified: #{notification_list.join(', ')}"
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module SK
    module Svn
      class MailNotifierTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
