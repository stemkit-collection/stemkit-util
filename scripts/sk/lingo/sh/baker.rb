# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/config.rb'
require 'sk/lingo/recipe/comments.rb'
require 'sk/lingo/recipe/content-layout.rb'

module SK
  module Lingo
    module Sh
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Recipe::Comments
        include SK::Lingo::Recipe::ContentLayout

        def initialize(*args)
          super :sh, *args
        end

        def accept(item)
          if enforced? or [ 'sh', nil ].include? item.extension
            proc {
              process(item)
            }
          end
        end

        def process(item)
          save item, make_content(item)
          make_executable item
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def make_block_comments(*args)
          make_pound_comments(*args)
        end

        def make_line_comments(*args)
          make_pound_comments(*args)
        end
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
      module Sh
        class BakerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end

__END__

sh: 
  default:
    content: |
      TRACE=no

      print_usage()
      {
        print_error "USAGE: ${progname} [-v][-o][-a<argument>]"
      }

      main()
      {
        trap "cleanup_and_exit 5" HUP INT QUIT TERM
        trap "cleanup" EXIT 

        unset OPTION ARGUMENT

        while getopts ":hvoa:" option; do
          case "${option}" in
            o)
              OPTION=yes
            ;;
            a)
              ARGUMENT="${OPTARG}"
            ;;
            v)
              TRACE=yes
            ;;
            h)
              print_usage_and_exit 0
            ;;
            *)
              print_usage_and_exit
            ;;
          esac
        done

        shift `expr "${OPTIND}" - 1`
        [ "${#}" -ne 0 ] && print_usage_and_exit

        return 0
      }

      :<<:
      Variables:
        progpath - This script file full path
        progname - Name of this script file

      Functions:
        _echo() - Most suitable echo command (echo or echo -e).
        _awk() - Most suitable awk command (awk or nawk)
        print_message() - Echo parameters to the original stdout (| for start line)
        print_error() - print_message() to the original stderr
        print_usage_and_exit() - Print usage and exit with argument or 2
        register_for_cleanup() - Add entries to be cleaned up. Variables OK.
        suppress_error_output() - Redirect stderr to /dev/null for cmdline.
        suppress_output() - Redirect stdout and stderr to /dev/null for cmdline.
        trace_and_run() - Print cmdline if TRACE is yes, then execute.

        figure_full_program_path()
        figure_full_path()
        find_file_in_path()
        resolve_symlink()
        resolve_symlink_chain()

        is_list_member()
        is_path()
        is_absolute_path()
        is_regular_file()
        is_program()
      :

      figure_full_program_path()
      {
        file="${1}"
        is_path "${file}" || {
          file=`find_file_in_path "${file}" "${PATH}"`
        }
        figure_full_path "${file}"
      }

      figure_full_path()
      {
        echo `absolute_location "${1}"`/`basename "${1}"`
      }

      find_file_in_path()
      {
        file="${1}"
        path="${2}"

        ifs="${IFS}"
        IFS=:
        set entry ${path}
        shift
        IFS="${ifs}"

        for directory in "${@}"; do
          path="${directory}/${file}"
          is_regular_file "${path}" && {
            _echo "${path}"
            return 0
          }
        done
        return 1
      }

      resolve_symlink()
      {
        set entry `resolve_symlink_chain "${@}"`
        echo "${2}"
      }

      resolve_symlink_chain()
      {
        file="${1}"
        set entry `suppress_error_output "ls -ld '${file}'"`

        case "${2}" in
          l*)
            shift `expr "${#}" - 1`

            link="${1}"
            is_absolute_path "${link}" || {
              link=`dirname "${file}"`/${link}
            }
            echo `resolve_symlink_chain "${link}"` "${file}"
          ;;
          *)
            echo "${file}"
          ;;
        esac
      }

      absolute_location()
      {
        (cd `dirname "${1}"` && pwd)
      }

      is_list_member()
      {
        item="${1}"
        shift

        for entry in "${@}"; do
          [ "${entry}" = "${item}" ] && return 0
        done

        return 1
      }

      is_path()
      {
        case "${1}" in
          /* | */* | */ )
            return 0
          ;;
        esac

        return 1
      }

      is_absolute_path()
      {
        case "${1}" in
          /*)
            return 0
          ;;
        esac

        return 1
      }

      is_regular_file()
      {
        suppress_output "ls -ldL '${1}' | grep '^-'"
      }

      invoke_file_command()
      {
        file `resolve_symlink "${1}"`
      }

      is_program()
      {
        file="${1}"
        is_regular_file "${file}" && {
          suppress_output "invoke_file_command '${file}' | grep 'executable'"
        }
      }

      print_usage_and_exit()
      {
        print_usage
        exit "${1:-2}"
      }

      print_message()
      {
        _echo "${@}" | sed '/^[ \t]*$/d;s/^[ \t]*|//' 1>&3 
      }

      print_error()
      {
        print_message "${@}" 3>&4
      }

      suppress_output()
      {
        "${@}" >/dev/null 2>&1
      }

      suppress_error_output()
      {
        "${@}" 2>/dev/null
      }

      trace_and_run()
      {
        [ "${TRACE}" = yes ] && {
          print_error "=> ${@}"
        }
        "${@}"
      }

      cleanup_list=
      register_for_cleanup()
      {
        for item in "${@}"; do
          cleanup_list="${item}<:>${cleanup_list}"
        done
      }

      cleanup()
      {
        ifs="${IFS}"
        IFS="<:>"
        set entry ${cleanup_list}
        shift
        IFS="${ifs}"

        for entry in "${@}"; do
          eval entry="${entry}"
          [ "${entry:+set}" = set ] && {
            trace_and_run rm -rf "${entry}"
          }
        done

        cleanup_list=
      }

      cleanup_and_exit()
      {
        cleanup
        exit "${1:-1}"
      }

      if [ "`echo -e`" = "-e" ]; then
        _echo() {
          echo "${@}"
        }
      else
        _echo() {
          echo -e "${@}"
        }
      fi

      if ( nawk 'BEGIN { exit 0 }' ) >/dev/null 2>&1; then
        _awk() {
          nawk "${@}"
        }
      else
        _awk() {
          awk "${@}"
        }
      fi

      progpath=`figure_full_program_path "${0}"`
      progname=`basename "${progpath}"`

      exec 3>&1 4>&2

      main "${@}"
      exit "${?}"
