# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'net/smtp'
require 'tsc/errors.rb'
require 'tsc/contrib/mailfactory.rb'

module SK
  module Svn
    module Hook
      module ErrorMailer
        def report_error(message, &block)
          return unless block
          begin
            block.call
          rescue Exception => exception
            return if exception.is_a?(SystemExit)

            report = [
              "SVN[#{repository.inspect}] #{message}",
              *TSC::Error.textualize(exception, :stderr => true, :backtrace => true)
            ]

            $stderr.puts report
            begin
              notify_by_email(report)
            rescue Exception => exception
              $stderr.puts "ERROR: Mail notification failed", TSC::Error.textualize(exception, :stderr =>true, :backtrace => true)
            end
          end
        end

        def notify_by_email(report)
          mail = MailFactory.new
          mail.subject = report.first
          mail.text = report.join("\n")
          mail.to = config.admin
          mail.from = config.notify_from


          Net::SMTP.start('127.0.0.1', 25, config.domain) { |smtp|
            smtp.send_message(mail.to_s(), mail.from, mail.to)
          }
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module SK
    module Svn
      module Hook
        class ErrorMailerTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end
