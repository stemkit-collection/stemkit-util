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
  it "should merge strings as hashes in contructor" do
    d = SK::Config::Data.new 'aaa', { 'bbb' => 'ccc', 1 => 2 }, 'bbb'

    d.should == Hash[
      'aaa' => {},
      'bbb' => 'ccc',
      '1' => 2
    ]
  end

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

    describe "for arrays" do
      it "should not modify receiver if not present in other" do
        d = SK::Config::Data.merge [ 1, 2 ], {}

        d.should == [ 1, 2 ]
      end

      it "should expand elements if presend in hash" do
        d = SK::Config::Data.merge [ :a, :b ], Hash[ :a => { 1 => 2 }, :c => 'u' ]
        d.should == [ Hash[ 'a' => { '1' => 2 } ], :b ]
      end
    end
  end
end
