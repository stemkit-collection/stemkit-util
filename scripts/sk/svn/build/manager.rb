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
            if hierarchy_changed_since? last_build
              next_build = last_build.next

              api_changed = hierarchy_changed_since? last_build, 'include'
              update_build_config(next_build, api_changed, _stack)

              branch_off next_build
              $stderr.puts "Created build #{next_build} for #{credentials}"
            else
              $stderr.puts "Last build #{last_build} is up to date for #{credentials}"
            end
          end
        end

        def credentials
          "#{product} #{release} at #{top.inspect}"
        end

        def last_build
          @last_build ||= builds.last.to_i
        end

        def branch_off(build)
          launch [
            'svn', 'cp', '-q', trunk_url, File.join(builds_url, build.to_s), 
            '-m', "[BRANCH] #{product} #{release}, build #{build}"
          ]
        end

        def builds
          collect_build_info.map { |_build|
            _build.to_i
          }.sort
        end

        def hierarchy_changed_since?(build, *locations)
          return true if build == 0

          dirs = locations.map { |_location|
            _location.split(File::SEPARATOR)
          }
          dirs << [] if dirs.empty?

          dirs.any? { |_item|
            trunk_top = File.join(trunk_url, *_item)
            build_top = File.join(builds_url, build.to_s, *_item)
            launch("svn diff #{build_top} #{trunk_top}").first.empty? == false
          }
        end

        private
        #######

        def product
          build_config['product']
        end

        def release
          build_config['release']
        end

        def collect_build_info
          launch("svn ls #{builds_url}").first.map { |_entry|
            _entry.scan(%r{^(\d+)/})
          }.flatten
        end

        def update_build_config(build, is_api_changed, undo)
          original_build_config = build_config.clone
          undo.add {
            build_config.replace original_build_config
          }
          message = [ "#{product} #{release} - new build #{build}" ]

          build_config['build'] = build
          build_config['library-major'] = 0 if build == 1

          if is_api_changed
            build_config['library-major'] += 1

            message << "new library major #{build_config['library-major']}"
          end

          save_build_config build_config, message.join(', ')
          undo.add {
            save_build_config original_build_config, 'Revering to the previous content because of errors'
          }
        end

        def save_build_config(config, message)
          cwd = Dir.getwd
          Dir.temporary(working_area) do
            Dir.cd cwd do
              file = File.join(working_area, build_config_name)
              launch "svn co #{config_url} #{working_area}"

              File.open(file, 'w') do |_io|
                _io.puts YAML.dump(config)
              end

              launch [
                'svn', 'commit', file, '-m', message
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
