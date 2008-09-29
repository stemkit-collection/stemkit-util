# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'sk/config/data.rb'

describe SK::Config::Data do
  describe "class method merge()" do
    describe "for its own instances" do
      it "should merge hashes" do
        d = SK::Config::Data[
          :s1 => { :h1 => "aaa", :h2 => "bbb" }
        ]
        SK::Config::Data.merge d, :s1 => { :h1 => 'z', :h3 => 'b' }, :s2 => 'u'
        d.should == Hash[
          's1' => Hash[ 'h1' => 'z', 'h2' => 'bbb', 'h3' => 'b' ],
          's2' => 'u'
        ]
      end

      it "should deep merge arrays" do
        d1 = SK::Config::Data[
          :system => [
            { :s1 => [ :h1, :h2 ] },
            { :s2 => [ :h1 ] }
          ]
        ]

        d2 = SK::Config::Data[
          :system => [ :s4, :s1 ]
        ]
        SK::Config::Data.merge d2, d1

        d2[:system].should == [ :s4, Hash[ "s1" => [ :h1, :h2 ] ] ]
      end
    end

    describe "for hashes" do
      it "should merge hashes" do
        h = Hash[
          :s1 => { :h1 => "aaa", :h2 => "bbb" }
        ]
        d = SK::Config::Data.merge h, :s1 => { :h1 => 'z', :h3 => 'b' }, :s2 => 'u'
        d.should be_instance_of(SK::Config::Data)

        d.should == Hash[
          's1' => Hash[ 'h1' => 'z', 'h2' => 'bbb', 'h3' => 'b' ],
          's2' => 'u'
        ]
      end
    end
  end
end
