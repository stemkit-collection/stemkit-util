=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/svn/look.rb'

module SK
  module Svn
    class RevisionLook < Look
      attr_reader :revision

      def initialize(repository, revision)
        super repository
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
          property? && [
            'Property Change Paths:',
            '---------------------',
            shift(2, property)
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
            shift(2, uncategorized)
          ],
        ].flatten.compact
      end

      protected
      #########

      def svnlook_item_arguments
        [ '-r', revision ]
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Svn
      class RevisionLookTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
