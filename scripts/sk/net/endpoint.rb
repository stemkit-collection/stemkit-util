=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'tsc/errors.rb'

module SK
  module Net
    class Endpoint
      attr_reader :host, :port

      class NoHostError < TSC::Error
        def initialize
          super "Host not specified"
        end
      end

      class NoPortError < TSC::Error
        def initialize(host)
          super "Port not specified for host #{host.inspect}"
        end
      end

      def initialize(*args)
        host, *default_ports = args.flatten.compact.tap { |_hostspec, *_ports|
          break [ _hostspec[:host], _hostspec[:port], *_ports ] if Hash === _hostspec
        }
        host.to_s.split(':').tap { |_host, *_ports|
          @host = _host.to_s.strip
          @port = filter_ports(_ports.reverse + default_ports).flatten.compact.first.to_i
        }
        raise NoHostError if @host.empty?
        raise NoPortError, @host if @port.zero?
      end

      def to_s
        [ host, port ].join(':')
      end

      def inspect
        to_s.inspect
      end

      private
      #######

      def filter_ports(ports)
        ports.map { |_item|
          _item.to_s.strip.scan(%r{^\d+$})
        }
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Net
      class EndpointTest < Test::Unit::TestCase
        def test_no_host
          assert_raises Endpoint::NoHostError do
            SK::Net::Endpoint.new
          end
        end

        def test_no_port
          assert_raises Endpoint::NoPortError do
            SK::Net::Endpoint.new "abc"
          end
        end

        def test_simple_host_and_numeric_port
          endpoint = SK::Net::Endpoint.new "aaa", 45
          assert_equal "aaa", endpoint.host
          assert_equal 45, endpoint.port

          assert_equal "aaa:45", endpoint.to_s
        end

        def test_simple_host_and_several_ports
          endpoint = SK::Net::Endpoint.new "aaa", "hohoho", "17", 45
          assert_equal "aaa", endpoint.host
          assert_equal 17, endpoint.port

          assert_equal '"aaa:17"', endpoint.inspect
        end

        def test_simple_host_with_port
          endpoint = SK::Net::Endpoint.new "aaa:55", "hohoho", "17", 45
          assert_equal "aaa", endpoint.host
          assert_equal 55, endpoint.port
        end

        def test_simple_host_with_several_ports
          endpoint = SK::Net::Endpoint.new "bbb:55:1", "hohoho", "17", 45
          assert_equal "bbb", endpoint.host
          assert_equal 1, endpoint.port
        end

        def test_hashed_host_and_port
          endpoint = SK::Net::Endpoint.new :host => "uuu", :port => 19
          assert_equal "uuu", endpoint.host
          assert_equal 19, endpoint.port
        end

        def setup
        end
      end
    end
  end
end
