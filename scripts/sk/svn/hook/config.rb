# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'yaml'

module SK
  module Svn
    module Hook
      class Config
        attr_reader :content

        def initialize(file)
          @content = begin
            YAML.parse(IO.readlines(file).join) or "Error parsing #{file.inspect}"
          end.transform
        end

        def repository_base
          @repository_base ||= File.expand_path(content['repository_base'])
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module SK
    module Svn
      module Hook
        class ConfigTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end
