# vim: set sw=2:

require 'sk/lingo/item.rb'
require 'tsc/dataset.rb'

describe SK::Lingo::Item do
  describe "with specified namespace" do
    attr_reader :bakery, :item

    before do
      @bakery = mock('bakery')
    end

    it "should process name with extension" do
      bakery.expects(:options).returns TSC::Dataset[ :namespace => 'aaa.bbb' ]
      @item = SK::Lingo::Item.new 'ccc.java', bakery

      item.name.should == 'ccc'
      item.extension.should == 'java'
      item.namespace.should == [ 'aaa', 'bbb' ]
      item.location.should == '.'
    end
  end
end
