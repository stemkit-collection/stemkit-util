=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'etc'
require 'tsc/config.rb'

module SK
  module Lingo
    class Config
      attr_reader :options, :hash

      def initialize(options, *args)
        @options = options
        @hash = args.inject({}) do |_hash, _item|
          _hash.merge TSC::Config.convert(_item)
        end
      end

      def update_from_file
        hash.update TSC::Config.parse(config_file).hash if File.exist?(config_file)

        self
      end

      def indent
        @indent ||= (options.indent || hash['indent']).to_i
      end

      def copyright_holders
        holders = Array(hash['copyright_holders'])
        holders.push user_credentials.gecos if holders.empty?

        lines holders
      end

      def authors
        authors = Array(hash['authors'])
        authors.push user_credentials.gecos if authors.empty?

        lines authors
      end

      def license
        lines hash['license']
      end

      def sh
        lines hash['sh']
      end

      def header_includes
        lines hash['header_includes']
      end

      def header_bottom
        lines hash['header_bottom']
      end

      def body_top
        lines hash['body_top']
      end

      def body_includes
        lines hash['body_includes']
      end

      def extends
        lines hash['extends']
      end

      def initializes
        lines hash['initializes']
      end

      def data
        lines hash['data']
      end
      
      def constructors
        klass = Struct.new(:parameters, :body, :comments)
        process_methods(hash['factory']) { |_returns, _name, _parameters, _body, _comments|
          klass.new(_parameters, _body, _comments) if _name == 'constructor'
        }.compact
      end

      def destructors
        klass = Struct.new(:type, :body, :comments)
        process_methods(hash['factory']) { |_returns, _name, _parameters, _body, _comments|
          klass.new(_returns, _body, _comments) if _name == 'destructor'
        }.compact
      end

      def class_init
        lines hash['class_init']
      end

      def public_methods
        @public_methods ||= map_methods(hash['public_methods'])
      end

      def protected_methods
        @protected_methods ||= map_methods(hash['protected_methods'])
      end

      def private_methods
        @private_methods ||= map_methods(hash['private_methods'])
      end
      
      private
      #######
      def lines(content)
        unit = nil
        content.to_s.map { |_line| 
          # Here the line gets re-indented to the value specified 
          # either in the config file or on the command line (-i).
          #
          spaces, line = _line.chomp.scan(%r{^(\s*)(.*)$}).first
          offset = spaces.count(" ") + spaces.count("\t") * 8
          unit ||= (offset unless offset.zero?)

          (unit ? ' ' * ((offset/unit)*indent) : '') + line
        }
      end

      def process_methods(methods, &block)
        return [] unless block and Hash === methods

        methods.map { |_declaration, _body|
          returns, name, parameters = _declaration.scan(%r{^(.*?)\s*(\w+)\s*([(][^)]*[)].*)$}).first
          comments, body = lines(_body).partition { |_line|
            _line.match %r{^\s*//}
          }
          block.call returns, name, parameters, body, comments
        }
      end

      def map_methods(methods)
        klass = Struct.new(:returns, :signature, :body, :comments)
        process_methods(methods) { |_returns, _name, _parameters, _body, _comments|
          klass.new _returns, "#{_name}#{_parameters}", _body, _comments
        }
      end

      def config_file
        @config_file ||= options.config? ? options.config : begin
          file = 'new.yaml'
          src_from_current = Dir.pwd.scan(%r{^(.+/src)(/.*)*$}).first

          src_from_current && [ [], ['*'], ['*','*'] ].map { |_components|
            Dir[ File.join(*([src_from_current.first] + _components + ['config', file])) ]
          }.flatten.first
        end || File.join(user_credentials.dir, ".#{file}")
      end

      def user_credentials
        @credentials ||= Etc.getpwuid
      end

      def find_src_from_current
        @src = Dir.pwd.gsub(%r{^(.+/src)(/.*)$}, '\1')
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Lingo
      class ConfigTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
