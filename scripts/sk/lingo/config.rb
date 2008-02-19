=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'etc'
require 'yaml'

module SK
  module Lingo
    class Config
      def initialize(options, hash = nil)
        @options = options
        @config = (hash && check_config(hash, 'Bad given config')) || begin
          parser = proc { |_io|
            result = YAML.parse(_io)
            result.transform if result
          }
          config = check_config parser.call(DATA), 'Bad default config'

          file = find_config_file
          if File.exist?(file)
            config.update check_config(File.open(file, &parser), "Bad config in #{file.inspect}")
          end

          config
        end

        return unless @options.has_key? 'mode'

        mode = @config[@options['mode']]
        @config.update mode if Hash === mode
      end

      def check_config(config, message)
        raise message unless Hash === config
        config
      end

      def indent
        @indent ||= (@options['indent'] || @config['indent']).to_i
      end

      def copyright_holders
        holders = Array(@config['copyright_holders'])
        holders.push user_credentials.gecos if holders.empty?

        lines holders
      end

      def authors
        authors = Array(@config['authors'])
        authors.push user_credentials.gecos if authors.empty?

        lines authors
      end

      def license
        lines @config['license']
      end

      def sh
        lines @config['sh']
      end

      def header_includes
        lines @config['header_includes']
      end

      def header_bottom
        lines @config['header_bottom']
      end

      def body_top
        lines @config['body_top']
      end

      def body_includes
        lines @config['body_includes']
      end

      def extends
        lines @config['extends']
      end

      def initializes
        lines @config['initializes']
      end

      def data
        lines @config['data']
      end
      
      def constructors
        klass = Struct.new(:parameters, :body, :comments)
        process_methods(@config['factory']) { |_returns, _name, _parameters, _body, _comments|
          klass.new(_parameters, _body, _comments) if _name == 'constructor'
        }.compact
      end

      def destructors
        klass = Struct.new(:type, :body, :comments)
        process_methods(@config['factory']) { |_returns, _name, _parameters, _body, _comments|
          klass.new(_returns, _body, _comments) if _name == 'destructor'
        }.compact
      end

      def class_init
        lines @config['class_init']
      end

      def public_methods
        @public_methods ||= map_methods(@config['public_methods'])
      end

      def protected_methods
        @protected_methods ||= map_methods(@config['protected_methods'])
      end

      def private_methods
        @private_methods ||= map_methods(@config['private_methods'])
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

      def find_config_file
        config = 'config'
        @config_file ||= @options.has_key?(config) ? @options[config] : begin
          file = 'new.yaml'
          src_from_current = Dir.pwd.scan(%r{^(.+/src)(/.*)*$}).first

          src_from_current && [ [], ['*'], ['*','*'] ].map { |_components|
            Dir[ File.join(*([src_from_current.first] + _components + [config, file])) ]
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
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
