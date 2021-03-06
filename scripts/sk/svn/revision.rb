=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'tsc/dataset.rb'

require 'time'
require 'tempfile'

module SK
  module Svn
    class Revision
      attr_reader :repository

      DEFAULT_PARAMS = { :log => nil }

      def initialize(repository, params = {})
        @repository, @params = repository, TSC::Dataset.new(DEFAULT_PARAMS).update(params)
        @values = {}
      end

      def update(params)
        @params.update(params)
        self
      end

      def number
        @values[:number] ||= @params.log.fetch('revision').to_i
      end

      def author
        @values[:author] ||= @params.log.fetch('author').first
      end

      def date
        @values[:date] ||= translate_xml_time @params.log.fetch('date').first
      end

      def message
        @values[:message] ||= @params.log.fetch('msg').first
      end

      def message=(content)
        @values[:message] = content.to_s
      end

      def save_message(bypass = false)
        Tempfile.open("sk_") { |_tempfile|
          begin
            _tempfile.write(message)
            _tempfile.close

            @repository.svnadmin 'setlog', '-r', number, ('--bypass-hooks' if bypass), _tempfile.path
          ensure
            _tempfile.unlink
          end
        }
      end

      def invoke_hook_for(name)
        repository.path.join('hooks').join(name).tap { |_hook|
          "Hook for #{name} is not configured in repository #{repository.name.inspect}".tap { |_message|
            raise _message unless _hook.executable?
          }
          repository.launch _hook, repository.path, number
        }
      end

      def items
        @values[:items] ||= begin
          Hash.new.tap { |_result|
            getlog('-v').first.fetch('paths').first.fetch('path').each do |_item|
              (_result[normalize_path_action(_item['action'])] ||= []) << _item['content']
            end
          }
        end
      end

      def reload
        return if number.zero?
        @values = {}

        update :log => getlog.first
      end

      def getlog(*args)
        @repository.getlog('-r', number, *args)
      end

      private
      #######

      def normalize_path_action(action)
        case action
          when 'M'
            :modified

          when 'D'
            :deleted

          when 'A', 'R'
            :added
        end
      end

      def translate_xml_time(line)
        line.scan(%r{^(.*)T(.*)[.](.*)Z$}).first.tap { |_items|
          raise "Wrong time for revision #{number}" unless _items.size == 3
          return gmt_to_local *_items
        }
      end

      def gmt_to_local(date, time, ms)
        Time.parse("#{date} #{time} GMT")
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Svn
      class RevisionTest < Test::Unit::TestCase
        def setup
        end

        def test_nothing
        end
      end
    end
  end
end
