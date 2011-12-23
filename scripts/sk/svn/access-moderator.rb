=begin
  vim: sw=2:
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/svn/hook/plugin/generic.rb'
require 'tsc/border-box.rb'

module SK
  module Svn
    class AccessModerator < Hook::Plugin::Generic
      def process(info)
        access = config.repositories[info.depot]['access'] or return 

        [access].flatten.each do |_access|
          _access.each_pair do |_item, _params|
            allow_patterns = make_pattern_list(_params['allow'])
            deny_patterns = make_pattern_list(_params['deny'] || '^.+$')
            path_patterns = make_pattern_list(_item)

            info.affected.each do |_path|
              next unless path_patterns.any? { |_pattern|
                _path =~ _pattern 
              }
              next unless deny_patterns.any? { |_pattern|
                info.author =~ _pattern
              }
              next if allow_patterns.any? { |_pattern|
                info.author =~ _pattern
              }
              $stderr.puts TSC::BorderBox[ _params['message'] ]
              raise 'Access denied'
            end
          end
        end
      end

      def make_pattern_list(*args)
        args.flatten.compact.map { |_item|
          pattern = _item.to_s.strip
          Regexp.new [ ('^\s*' unless pattern.slice(0) == ?^), pattern ].join
        }
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
  module SK
    module Svn
      class AccessModeratorTest < Test::Unit::TestCase
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
