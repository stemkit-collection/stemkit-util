=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'
require 'time'

module SK
  module Cli
    module Svn
      class LocalTimeTuner < SK::Cli::Tuner
        def process(io)
          io.each do |_line|
            app.output_info translate_xml_time(_line)
          end

          display_errors_if_any
        end

        private
        #######

        def translate_xml_time(line)
          line.gsub(%r{(<date>)(.*)T(.*)[.](.*)Z(</date>)}) { |*_match|
            $1 + gmt_to_local($2, $3, $4) + $5
          }
        end

        def gmt_to_local(date, time, ms)
          Time.parse("#{date} #{time} GMT").strftime("%Y-%m-%dT%H:%M:%S.#{ms}Z%Z")
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Cli
      module Svn
        class LocalTimeTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
