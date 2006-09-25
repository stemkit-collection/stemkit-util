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

        def request_wait_timeout
          @request_wait_timeout ||= begin
            timeout = content['request_wait_timeout'].to_s
            timeout =~ %r{^\d+$} ? timeout.to_i : 60
          end

          @request_wait_timeout.zero? ? nil : @request_wait_timeout
        end

        def repository_path(repository)
          File.join repository_base, repository
        end

        def plugins(repository)
          list = repositories[repository]['plugins'] rescue nil
          Array(list)
        end

        def notify(repository)
          list = repositories[repository]['notify'] rescue nil
          Array(list)
        end

        def url_base
          content['url_base']
        end

        def admin
          Array(content['admin'])
        end

        def notify_from
          (content['notify_from'] || "nobody@#{domain}").to_s
        end

        def domain
          (content['domain'] || 'localhost').to_s
        end

        def repositories
          content['repository'] || Hash.new
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
