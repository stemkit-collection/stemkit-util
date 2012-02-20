=begin
  vim: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

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
        notification_list = figure_notification_list(info)
        return if notification_list.empty?

        $stderr.puts "L: #{notification_list.inspect}"

        mail = MailFactory.new

        mail.subject = "SVN[#{info.depot}] #{info.revision}: #{info.log.to_s.map.first.chomp[0...70]}"
        mail.from = config.email_for_user(info.author)
        mail.to = notification_list
        mail.text = [ info.digest(config.url_base), info.diff ].flatten.join("\n")

        Net::SMTP.start('127.0.0.1', 25, config.domain) { |smtp|
          smtp.send_message(mail.to_s(), mail.from, mail.to)
        }
        $stderr.puts "Notified: #{notification_list.join(', ')}"
      end

      def figure_notification_list(info)
        Array(config.notify(info.depot)).map { |_param|
          element, *list = Array(_param).flatten
          item = element.to_s.strip
          if list.empty? == false
            pattern = Regexp.new [ ('^\s*' unless item.slice(0) == ?^), item ].join
            next unless info.affected.any? { |_path|
              pattern.match(_path)
            }
            break list if Hash === _param
            list
          else
            item
          end
        }.flatten.compact.uniq
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  require 'set'

  module SK
    module Svn
      class MailNotifierTest < Test::Unit::TestCase
        attr_reader :config, :notifier, :info

        def test_per_location_list
          info.stubs(:depot).returns 'abc'
          config.stubs(:notify).returns Hash[
            '.*?/bbb' => [ 'zzz', 'uuu' ],
            'ccc/uuu/' => 'bbb',
            '.*' => 'iii'
          ]
          info.stubs(:affected).returns [
            'aaa/zzz/ccc/bbb',
            'ccc/'
          ]

          assert_equal Set[ 'zzz', 'iii', 'uuu' ], Set[*notifier.figure_notification_list(info)]
        end

        def test_per_location_ordered_list
          info.stubs(:depot).returns 'abc'
          config.stubs(:notify).returns [
            { '.*?/bbb' => [ 'zzz', 'uuu' ] },
            { 'ccc/uuu/' => 'bbb' },
            { '.*' => 'iii' }
          ]
          info.stubs(:affected).returns [
            'aaa/zzz/ccc/bbb',
            'ccc/'
          ]

          assert_equal Set[ 'zzz', 'uuu' ], Set[*notifier.figure_notification_list(info)]
        end

        def test_simple_notification_list
          info.stubs(:depot).returns 'abc'
          config.stubs(:notify).returns [ 'aaa', 'bbb', 'ccc', 'aaa' ]

          assert_equal [ 'aaa', 'bbb', 'ccc' ], notifier.figure_notification_list(info)
        end

        def setup
          @config = mock('Config')
          @info = mock('Info')
          @notifier = MailNotifier.new config
        end
      end
    end
  end
end
