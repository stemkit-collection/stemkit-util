# The weird series of -e options is needed here because make adds option -c
# to execute the command line, causing ruby syntax errors. So here we simply
# force numeric variable 'c' by assigning 0. '-c' after the last -e will 
# make a legal expression, while the actual parameter evaluation is done
# by the second -e.
#
SHELL = ruby -r fileutils -rubygems -I$(PATH) -e 'c=0' -e 'eval ARGV.first' -e

all:: 
	@ puts "Use 'make tests' or 'make specs' for unit tests or specs."

test tests spec specs:: 
	@ Dir['*/makefile'].map { |item| system "$(MAKE) -C #{File.dirname(item)} $(@)" }

test tests:: 
	@ require 'test/unit' and Dir['*.rb'].map { |item| require item }

spec specs:: 
	@ Dir['SPECS/*'].map { |item| load item, true }
	 
