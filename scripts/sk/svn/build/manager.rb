# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'yaml'
require 'tempfile'

require 'tsc/launch.rb'
require 'tsc/dtools.rb'
require 'tsc/ftools.rb'

module SK
  module Svn
    module Build
      class Manager
        attr_reader :top

        def initialize(top)
          @top = top
        end

        def make
          TSC::Error.undo Exception do |_stack|
            update_build_config(_stack)
            launch [
              'svn', 'cp', '-q', trunk_url, File.join(builds_url, last_build.next.to_s), '-m', reason
            ]
          end
        end

        def last_build
          builds.last.to_i
        end

        def builds
          launch("svn ls #{builds_url}").first.map { |_entry|
            _entry.scan(%r{^(\d+)/})
          }.flatten.map { |_build|
            _build.to_i
          }.sort
        end

        private
        #######

        def reason
          "[Build #{last_build.next}]"
        end

        def update_build_config(undo)
          save_build_config build_config.merge('build' => last_build.next)
          undo.add {
            save_build_config build_config
          }
        end

        def save_build_config(config)
          cwd = Dir.getwd
          Dir.temporary(working_area) do
            Dir.cd cwd do
              file = File.join(working_area, build_config_name)
              launch "svn co #{config_url} #{working_area}"

              File.open(file, 'w') do |_io|
                _io.puts YAML.dump(config)
              end

              launch [
                'svn', 'commit', file, '-m', "[Build #{config['build']}]"
              ]
            end
          end
        end

        def working_area
          @working_area ||= 'working-area' + '.' + last_build.to_s + '.' + Process.pid.to_s
        end

        def trunk_url
          @trunk_url ||= top_folder('trunk')
        end

        def builds_url
          @builds_url ||= top_folder('builds')
        end

        def build_config_name
          'build.yaml'
        end

        def config_url
          @config_url ||= File.join(trunk_url, 'config')
        end

        def build_config_url
          @build_config_url ||= File.join(config_url, build_config_name)
        end

        def build_config
          @build_config ||= begin
            content =launch("svn cat #{build_config_url}").first.join("\n")
            config = catch :config do
              (YAML.parse(content) or throw :config, nil).transform
            end
            Hash === config ? config : Hash.new
          end
        end

        def top_content
          @top_content ||= launch("svn ls #{top}").first
        end
        
        def top_folder(name)
          folder = File.join(top, name)
          raise "No #{folder.inspect}" unless top_content.include?(name + '/')

          folder
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module SK
    module Svn
      module Build
        class ManagerTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end
