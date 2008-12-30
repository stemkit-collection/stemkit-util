# vim: set sw=2:

require 'sk/lingo/item.rb'
require 'tsc/dataset.rb'

describe SK::Lingo::Item do
  describe "with specified namespace" do
    attr_reader :item

    it "should process name with extension" do
      @item = SK::Lingo::Item.new 'ccc.java', TSC::Dataset[ :namespace => 'aaa.bbb' ]

      item.name.should == 'ccc'
      item.extension.should == 'java'
      item.namespace.should == [ 'aaa', 'bbb' ]
      item.location.should == '.'
    end
  end
end
