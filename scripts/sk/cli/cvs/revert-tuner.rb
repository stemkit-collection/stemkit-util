=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'
require 'sk/cli/cvs/file.rb'

require 'tempfile'
require 'fileutils'

module SK
  module Cli
    module Cvs
      class RevertTuner < SK::Cli::Tuner
        def check_option(option)
          depot << option
          nil
        end

        def process(io)
          raise 'No items specified' if depot.empty?
          io.each do |_line|
            case _line
              when %r{^cvs\s+status:\s+Examining\s+(.*?)\s*$}
                set_folder $1

              when %r{^File:\s+(no file\s*)?(.*?)\s+Status:\s+(.*?)\s*$}
                Cvs::File.new($2, folder, $3, $1 ? false : true).tap do |_file|
                  next unless _file.added?
                  next unless depot.include? _file.path.to_s

                  Tempfile.open(_file.path.basename) do |_tempfile|
                    _tempfile.close
                    FileUtils.cp _file.path.to_s, _tempfile.path, :verbose => false
                    begin
                      system('cvs', 'rm', '-f', _file.path.to_s)
                      @reverted = true
                    ensure
                      FileUtils.cp _tempfile.path, _file.path.to_s, :verbose => false
                    end
                  end
                end
            end
          end

          raise 'No items found' unless @reverted
        end

        private
        #######

        def depot
          @depot ||= []
        end

        def set_folder(folder)
          @folder = Pathname.new(folder)
        end

        def folder
          @folder or raise 'No folder information encountered'
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
      module Cvs
        class RevertTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
