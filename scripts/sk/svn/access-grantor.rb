=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/svn/hook/plugin/generic.rb'

module SK
  module Svn
    class AccessGrantor < Hook::Plugin::Generic
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
              box _params['message']
              raise 'Access denied'
            end
          end
        end
      end

      def box(*args)
        message = args.flatten.compact.map { |_item| Array(_item) }.flatten.map { |_line|
          _line.chomp
        }
        size = message.map { |_line| _line.size }.max
        $stderr.puts [
          "+-#{'-'*size}-+",
          message.map { |_line|
            "| #{_line}#{' '*(size-_line.size)} |"
          },
          "+-#{'-'*size}-+"
        ]
      end

      def make_pattern_list(*args)
        args.flatten.compact.map { |_item|
          pattern = _item.to_s.strip
          Regexp.new [ ('^\s*' unless pattern.slice(0) == ?^), pattern ].join
        }
      end

      def validate(user, allow, deny)
        allow.each do |_pattern|
          return true if user =~ _pattern
        end

        deny.each do |_pattern|
          return false if user =~ _pattern
        end

        true
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Svn
      class AccessGrantorTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
