# The weird series of -e options is needed here because make adds option -c
# to execute the command line, causing ruby syntax errors. So here we simply
# force numeric variable 'c' by assigning 0. '-c' after the last -e will 
# make a legal expression, while the actual parameter evaluation is done
# by the second -e.
#
RUBY = ruby -rubygems -I$(PATH) 
SHELL = $(RUBY) -r fileutils -r sk/file-locator -e 'c=0' -e 'eval ARGV.first' -e

all:: 
	@ puts "Use 'make tests' or 'make specs' for unit tests or specs."

test tests spec specs:: 
	@ Dir['*/makefile'].map { |item| system "$(MAKE) -C #{File.dirname(item)} $(@)" or exit(2) }

test tests:: 
	@ Dir['*.rb'].each { |item| system "$(RUBY) #{item}" or exit(2) }

spec specs:: 
	@ File.directory?("SPECS") and exec %Q[ $(RUBY) -ISPECS -S spec --require sk/spec/config --color -fs #{SK::FileLocator.new("SPECS").find_bottom_up("*[_-]spec.rb").join(' ')} ]
