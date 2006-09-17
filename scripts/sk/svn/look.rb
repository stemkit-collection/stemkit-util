# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module SK
  module Svn
    class Look
      attr_reader :repository, :revision

      def initialize(repository, revision)
        @repository = repository
        @revision = revision
      end

      def digest(url_base = nil)
        [
          [
          "Revision: #{revision}",
          (url_base && "(#{url_base}/#{depot}/?Insurrection=log&r1=#{revision})")
          ].join(' '),
          "Author:   #{author}",
          "Date:     #{timestamp.inspect}",
          '', 
          'Log Message: ',
          '-----------',
          log,
          '', 
          modified? && [
            'Modified Paths:',
            '--------------',
            shift(2, modified)
          ],
          '',
          added? && [
            'Added Paths:',
            '-----------',
            shift(2, added)
          ],
          '',
          deleted? && [
            'Deleted Paths:',
            '-------------',
            shift(2, deleted)
          ],
          '',
          uncategorized? && [
            'Uncategorized Paths:',
            '-------------------',
            sift(2, uncategorized)
          ],
        ].flatten.compact
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
        @diff ||= svnlook('diff')
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

      private
      #######

      def svnlook(*args)
        launch([ 'svnlook', args, '-r', revision, repository ].flatten).first
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
            category, content = _entry.scan(%r{^(.)\s+(.*)$}).first
            case category
              when 'U'
                hash[:modified] << content
              when 'A'
                hash[:added] << content
              when 'D'
                hash[:deleted] << content
              when ' '
                last_categorized_content << "\n    " << content
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

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module Sk
    module Svn
      class LookTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
