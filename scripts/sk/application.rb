# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module SK
  # This class provides an application framework for any Ruby application.
  # It accepts option descriptions and provides command line parsing as well
  # as usage help formatting. It implements default options for help request
  # and verbose error reporting. Aslo provides pretty exception handling,
  # showing exeption(s) messages and, in case for verbose option, backtrace 
  # information.
  #
  class Application
    attr_reader :script_name, :script_location

    # Creates and application, passing it optional command line descriptor 
    # (if the first argument is aString) and an array of option descriptors  
    # (themselves arrays) in the form: 
    #    <option>, <description> [, <argument> [, <alias> ] ... ]
    #
    # <option> It is what must be specified with two leading dashes ('--') on 
    #   the command line.
    # <alias> It is a one-character option alias, to be specified with leadint
    #   dash ('-'). More than one may be specified.
    # <description> It is an option description that will appear in the usage
    #   print out.
    # <argument> If not nil, designates that an argument is required for an 
    #   option. Also, it will appear in the usage print out, enclosed in 
    #   angle brackets (<>).
    # 
    # The following options are always present: --help (-h) that prints out 
    # usage information, and --verbose (-v) that turns on verbose mode for
    # error diagnostics. When used with a block, invokes method 'start' with 
    # the specified block.
    #
    def initialize(*args, &block)
      require 'sk/errors.rb'
      require 'sk/option-registry.rb'

      @arguments = args.shift if String === args.first
      @registry = OptionRegistry.new

      @registry.add 'verbose', 'Turns verbose mode on', nil, 'v'
      @registry.add 'help', 'Prints out this message', nil, 'h'
      @registry.add_bulk(*args)

      @script_location, @script_name = File.split($0)
      @options = nil

      start(&block) if block
    end

    # Default start method that processes the command line arguments and
    # calls a specified block, if any, passing it a hash of collected 
    # options. A derrived class may override this method to so more
    # sofisticated processing.
    # 
    def start(&block) # :yields: options
      handle_errors do
        process_command_line
        block.call(options) if block
      end
    end

    # Returns a hash of parsed option values or an empty hash if 
    # options not processed yet.
    #
    def options
      @options or Hash.new
    end

    def verbose=(state)
      @options ||= Hash.new
      if state 
        @options['verbose'] = true
      else
        @options.delete('verbose')
      end
    end

    protected
    #########

    # Provides a harness for errors. Calls a specified block, rescueing
    # a specified list of exceptions to form pretty error messages and
    # correct exit code.
    #
    def handle_errors(*errors, &block) # :yields: options
      return unless block

      begin
        block.call(options)
      rescue *usage_errors => error
        print_error(error)
        print_usage('===')
        exit 2
      rescue Exception => exception
        case exception
          when SK::Error
            exception.each_error do |_error, *_strings|
              print_error _error, *_strings
            end
          when StandardError, Interrupt, *errors
            print_error exception
          else
            raise
        end
        exit 3
      end
    end

    # Processes command line according to the option descriptors provided on
    # creation.
    #
    def process_command_line(order = false)
      return @options if @options
      @options = Hash.new

      require 'getoptlong'
      require 'set'

      processor = option_processor.extend(Enumerable)

      processor.quiet = true
      processor.ordering = GetoptLong::REQUIRE_ORDER if order

      processor.map.to_set.divide { |_item1, _item2|
        _item1.first == _item2.first
      }.each do |_set|
        option, args = _set.to_a.transpose
        @options[option.first.slice(2..-1)] = args.size==1 ? args.first : args
      end

      return @options unless @options.has_key? 'help'
      print_usage
      exit 0
    end

    # Invokes a block, passing it the specified exit code, and then exits
    # with the same code. Provided only as a convenient way to write 
    # one-liner verifications.
    # 
    def do_and_exit(code = 0, &block) # :yields: exit_code
      block.call(code) if block
      exit code
    end

    # Returns true if no option processing yet or option 'verbose' 
    # was specified.
    #
    def verbose?
      return true unless @options
      @options.has_key? 'verbose'
    end

    def find_in_path(command)
      ENV.to_hash['PATH'].split(File::PATH_SEPARATOR).map { |_location|
        Dir[ File.join(_location, command) ].first
      }.compact
    end

    def adjust_ruby_loadpath(top)
      ruby_component = File.join 'lib', 'ruby'
      local_ruby_directory = File.join top, ruby_component
      return unless check_directory_exists local_ruby_directory

      pattern = File.join '.*', ruby_component, '(.*)'
      $:.each do |_loadpath|
        components = _loadpath.scan %r{^#{pattern}$}
        unless components.empty?
          _loadpath.replace File.join(local_ruby_directory, components.first.first)
        end
      end
    end

    private
    #######

    def option_processor
      require 'getoptlong'
      GetoptLong.new *@registry.entries.map { |_entry|
        option, description, argument, aliases = _entry.to_a

        [ option ] + aliases + [ 
          argument ? GetoptLong::REQUIRED_ARGUMENT : GetoptLong::NO_ARGUMENT
        ]
      }
    end

    def usage_errors
      require 'getoptlong'
      [ 
        SK::UsageError, 
        GetoptLong::InvalidOption, 
        GetoptLong::MissingArgument
      ]
    end

    def print_usage(*args)
      print_diagnostics args + [
        "USAGE: #{script_name} [<options>] #{@arguments}",
        unless @registry.entries.empty?
          [
            'Options:',
            @registry.format_entries.map { |_aliases, _option, _description|
              "  #{_aliases}#{_option}   #{_description}"
            }
          ]
        end
      ]
    end

    def print_error(exception, *strings)
      message = [ 'ERROR', script_name ] + strings.flatten + [ exception.message.strip ].map { |_m|
        _m.empty? ? exception.class.to_s : _m
      }
      print_diagnostics [
        message.join(': '),
        if verbose?
          [
            '<' + exception.class.name + '>',
            if exception.backtrace
              exception.backtrace.map { |_line|
                '  ' + _line.sub(%r{^#{script_location}/}, '')
              }
            end
          ]
        end
      ]
    end

    def print_diagnostics(*args)
      $stderr.puts args.flatten.compact
    end

    def check_directory_exists(path)
      File.stat(path).directory? if Dir[path].size == 1
    end

  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'set'

  module SK
    class Application
      def print_diagnostics(*args)
      end
    end

    class ApplicationTest < Test::Unit::TestCase
      def test_with_options
        app = SK::Application.new( 
          [ 'test', 'Test', 'thing', '-t', 'T' ], 
          [ 'install', 'Install' ]
        )
        ARGV.replace %w{ -v -ta -Tb -v --test c --install }
        result = app.start { |_options|
          _options
        }
        assert_equal 3, result.size
        assert_equal '', result.fetch('verbose')
        assert_equal '', result.fetch('install')

        test = result.fetch('test')

        assert_equal 3, test.size
        assert_equal Set.new(['a', 'b', 'c']), Set.new(test)
      end

      def test_error
        begin
          ARGV.replace %w{}
          SK::Application.new {
            raise 'Sample error'
          }
          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal false, exception.success?
        end
      end

      def test_bad_usage
        begin
          ARGV.replace %w{ -z }
          SK::Application.new.start

          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal false, exception.success?
        end
      end

      def test_successful_exit
        begin
          ARGV.replace %w{}
          SK::Application.new {
            exit 0
          }
          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal true, exception.success?
        end
      end

      def test_help
        begin
          ARGV.replace %w{ -h }
          SK::Application.new.start

          flunk 'No expected exception (SystemError)'
        rescue SystemExit => exception
          assert_equal true, exception.success?
        end
      end
    end
  end
end
