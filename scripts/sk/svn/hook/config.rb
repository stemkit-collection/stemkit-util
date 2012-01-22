=begin
  vim: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'yaml'

module SK
  module Svn
    module Hook
      class Config
        attr_reader :content

        def initialize(input)
          @content = YAML.parse(lines(input).join).tap { |_content|
            break _content.transform if _content
            raise "Error parsing input"
          }
        end

        def lines(input)
          return input.readlines if input.respond_to? :readlines
          IO.readlines(input.to_s)
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
          content['repository'] || Hash.new { |_hash, _key|
            _hash[_key] = Hash.new
          }
        end

        def email_for_user(name)
          user_info(name, 'e-mail', true) or [ name, domain ].join('@')
        end

        def user_info(name, info, keyless)
          users[name].tap { |_entry|
            break _entry[info] if Hash === _entry
            break nil unless keyless == true
          }
        end

        def users
          @users ||= begin
            content['users'].tap { |_registry|
              break Hash.new unless Hash === _registry
            }
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'stringio'

  module SK
    module Svn
      module Hook
        class ConfigTest < Test::Unit::TestCase
          def test_email_for_user_minimal_config
            input = StringIO.new("abc")
            Config.new(input).tap do |_config|
              assert_equal "abc@localhost", _config.email_for_user("abc")
            end
          end

          def test_email_for_user_with_domain
            input = StringIO.new %q{
              domain: example.com
            }
            Config.new(input).tap do |_config|
              assert_equal "u1@example.com", _config.email_for_user("u1")
            end
          end

          def test_email_for_user_with_domain_and_registry
            input = StringIO.new %q{
              domain: example.com
              users:
                gfb: gfb@company.com
                aaa:
                  e-mail: bbb@zzz.edu
            }
            Config.new(input).tap do |_config|
              assert_equal "gfb@company.com", _config.email_for_user("gfb")
              assert_equal "bbb@zzz.edu", _config.email_for_user("aaa")
            end
          end

          def setup
          end

          def teardown
          end
        end
      end
    end
  end
end
