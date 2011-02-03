=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'tsc/dataset.rb'
require 'sk/ruby.rb'

require 'time'
require 'tempfile'

module SK
  module Svn
    class Revision
      include SK::Ruby

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

        Tempfile.open("sk_") { |_tempfile|
          begin
            _tempfile.write(message)
            _tempfile.close

            @repository.svnadmin 'setlog', '-r', number, '--bypass-hooks', _tempfile.path
          ensure
            _tempfile.unlink
          end
        }
      end

      def items
        @values[:items] ||= begin 
          with Hash.new do |_result|
            getlog('-v').first.fetch('paths').first.fetch('path').each do |_item|
              (_result[normalize_path_action(_item['action'])] ||= []) << _item['content']
            end

            _result
          end
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
        with line.scan(%r{^(.*)T(.*)[.](.*)Z$}).first do |_items|
          raise "Wrong time for revision #{number}" unless _items.size == 3
          gmt_to_local *_items
        end
      end

      def gmt_to_local(date, time, ms)
        Time.parse("#{date} #{time} GMT")
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
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
