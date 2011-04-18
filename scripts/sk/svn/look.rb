# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'time'

module SK
  module Svn
    class Look
      attr_reader :repository

      def initialize(repository)
        @repository = repository
      end

      def author
        @author ||= info.slice(0)
      end

      def depot
        @depot ||= File.basename repository
      end

      def timestamp
        @timestamp ||= Time.parse info.slice(1)
      end

      def  log
        @log ||= info.slice(3..-1).join("\n")
      end

      def diff
        @diff ||= svnlook('diff',  '--no-diff-deleted', '--no-diff-added',  '--diff-copy-from')
      end

      def property?
        true if changed.has_key?(:property)
      end

      def property
        changed[:property]
      end

      def modified?
        true if changed.has_key?(:modified)
      end

      def modified
        changed[:modified]
      end

      def added?
        true if changed.has_key?(:added)
      end

      def added
        changed[:added]
      end

      def deleted?
        true if changed.has_key?(:deleted)
      end

      def deleted
        changed[:deleted]
      end

      def uncategorized?
        true if changed.has_key?(:uncategorized)
      end

      def uncategorized
        changed[:uncategorized]
      end

      def svnlook(*args)
        launch([ 'svnlook', args, svnlook_item_arguments, repository ].flatten).first
      end

      def affected
        changed.values.flatten.compact.uniq
      end

      private
      #######

      def svnlook_item_arguments
        raise TSC::NotImplementedError, :svnlook_item_arguments
      end

      def info
        @info ||= svnlook('info')
      end

      def changed
        @changed ||= begin
          hash = Hash.new { |_h, _k|
            _h[_k] = []
          }
          last_categorized_content = ''

          svnlook('changed', '--copy-info').each { |_entry|
            category, content = _entry.scan(%r{^(..).\s+(.*)$}).first
            case category
              when 'U '
                hash[:modified] << content

              when '_U'
                hash[:property] << content

              when 'UU'
                hash[:property] << content
                hash[:modified] << content

              when 'A '
                hash[:added] << content

              when 'D '
                hash[:deleted] << content

              when '  '
                last_categorized_content << ' ' << content
                next

              else
                hash[:uncategorized] << _entry
            end
            last_categorized_content = content
          }
          hash
        end
      end

      def shift(indent, content)
        content.map { |_entry|
          _entry.map { |_entry|
            (' ' * indent) + _entry
          }
        }
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  
  module Sk
    module Svn
      class LookTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end

        def teardown
        end
      end
    end
  end
end
