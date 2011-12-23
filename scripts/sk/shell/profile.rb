=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'etc'
require 'fileutils'
require 'tsc/dataset.rb'

module SK
  module Shell
    class Profile
      def start
        yield config if block_given?

        time = Time.now
        say "\n\nHello, #{userinfo.gecos}. It is #{time.strftime '%X %x'} now."
        check_my_other_sessions { |_count|
          "Currently you have other #{_count} session(s) at #{server.inspect}"
        } or (
          if File.exists? lastlog_file
            say "You haven't been logged on since #{IO.readlines lastlog_file}"
          else
            say "It seems to be your first logging on to the system"
          end
        )
        save_lastlog_time time

        say "\nYour terminal is #{term}, tty line - #{tty}"
        say "Display is #{display}" if display

        others = logged_users.select { |_user| 
          _user[0] != userinfo.name 
        }.map { |_user| _user[0] }.uniq

        if others.size > 0
          say "There are #{others.size} other users logged on: #{others.join ', '}"
        else
          say "You are the only user on the system"
        end
        say "\nDon't forget to say \"bye\" when finishing !!!\n\n"

        export :TERM, term
        export :DISPLAY, display
        export :SERVER, server
        export :SYSID, sysid
        export :USER, userinfo.name
        # export :HISTFILE, histfile
        # export :home, home
        export :PATH, path
        export :MANPATH, manpath

        return 0
      end

      def stop(seconds)
        h, m, s = divide 3, 60, seconds.to_i
        say
        say "[ The End of Session ]".center(40)
        check_my_other_sessions {
          "\nWARNING: You still have other sessions"
        }
        say
        say "You've been logged on for as long as #{h}h #{m}m #{s}s"
        say "See you later, #{userinfo.gecos} !!!"
        say
        save_lastlog_time Time.now

        sleep 3
        return 0
      end

      private
      #######

      def normalize_path_list(list)
        list.flatten.compact.map { |_item|
          case _item
            when TSC::Dataset
              [ _item.before, _item.content, _item.after ]

            else
              _item
          end
        }
      end

      def build_path(*list)
        normalize_path_list(list).flatten.map { |_dir| 
          Dir[ eval '%Q{' + _dir + '}' ].select { |_item|
            _item if File.directory? _item
          }
        }.flatten.compact.join ':'
      end

      def divide(times,value,*args)
        unless args.empty?
          return args if args.size == times
          divide times, value, args.first/value, args.first%value, *args[1..-1]
        end
      end

      def check_my_other_sessions
        users = logged_users.select { |_user| _user[0] == userinfo.name }
        if users.size > 1
          say yield(users.size - 1)
          say users.select { |_user| 
            _user[1] != tty
          }.map { |_user|
            "> on #{_user[1]}" + ( " from #{_user[2]}" if _user[2] ).to_s + " since #{_user[3]}"
          }
          true
        end
      end

      def save_lastlog_time(time)
        FileUtils.makedirs File.dirname(lastlog_file)
        File.open(lastlog_file,"w") do |_io| 
          _io.puts time.strftime('%X %x')
        end
      end

      def say(*args)
        $stderr.puts *args
      end

      def run(*args)
        $stdout.puts *args
      end

      def userinfo
        @userinfo ||= begin
          info = Etc::getpwuid
          class << info
            def dir
              ENV['HOME']
            end

            def name
              ENV['LOGNAME'] || super
            end
          end

          info
        end
      end

      def tty
        @tty ||= `tty`.chomp.split('/dev/').last
      end

      def logged_users
        @logged_users ||= `who`.lines.map { |_entry|
          array = _entry.split
          user = array[0]
          pty = array[1]
          origin = array.last.scan(%r{\((.*)\)}).first
          if origin
            origin = origin.first
            time = array[2..-2]
          else
            time = array[2..-1]
          end
          [ user, pty, origin, time.join(' ') ]
        }
      end

      def export(symbol,value)
        run "#{symbol}='#{value}' export #{symbol};" unless value.nil?
      end

      def parse_term
        unless @term
          @term = ENV['TERM']
          array = @term.split '%'
          @term, @display = array if array.size == 2
        end
      end

      def term
        parse_term
        @term
      end

      def display
        parse_term
        unless @display
          @display = "#{current_session[2]}:0.0" if current_session[2]
        end
        @display
      end

      def current_session
        @current_session ||= logged_users.select { |_user|
          _user[0] == userinfo.name and _user[1] == tty
        }.first || []
      end

      def server
        @server ||= `uname -n`.chomp.split('.').first.downcase
      end

      def home
        @home ||= userinfo.dir
      end

      def sysid
        @sysid ||= begin
          require 'tsc/platform.rb'
          TSC::Platform.current.name
        rescue LoadError, TSC::Platform::UnsupportedError
          PLATFORM
        end
      end

      def lastlog_file
        @lastlog_file ||= "#{home}/.hostspecific/#{server}-lastlog"
      end

      def histfile
        @histfile ||= "#{home}/.hostspecific/#{server}-history"
      end

      def path
        @path ||= build_path(config.path, ENV['PATH'].split(':'))
      end

      def manpath
        @manpath ||= build_path(config.manpath)
      end

      def config 
        @config ||= TSC::Dataset[ 
          :path => TSC::Dataset[
            :before => [],
            :after => [],
            :content => %w{
              #{home}/bin/#{sysid} 
              #{home}/bin
              #{home}/local/platform/#{sysid}/bin
              #{home}/local/#{sysid}/bin
              #{home}/local/bin
              /opt/*/platform/#{sysid}/bin
              /sbin 
              /opt/ansic/bin
              /usr/vac/bin
              /opt/SUNWspro/bin 
              /usr/local/bin 
              /usr/ccs/bin 
              /bin /usr/bin /usr/sbin 
              /usr/ucb /usr/bsd 
              /etc /usr/etc /usr/java1.2/bin /c/jdk1.2.2/bin
              /usr/bin/X11 /usr/X11/bin /usr/openwin/bin
              /usr/X11/demo /usr/openwin/demo
              /opt/imake/bin
              /usr/contrib/bin
              /usr/contrib/win32/bin
              /dev/fs/C/SFU-ROOT/common
              /dev/fs/C/WINDOWS/system32
            }
          ],
          :manpath => TSC::Dataset[
            :before => [],
            :after => [],
            :content => %w{
              /usr/man
              /usr/share/man
              /usr/openwin/share/man
              /opt/SUNWspro/man
              /usr/local/man
              /usr/local/samba/man
              /usr/local/fvwm95/man
            }
          ] 
        ]
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Shell
      class ProfileTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
