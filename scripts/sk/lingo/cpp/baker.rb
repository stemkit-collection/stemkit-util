=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/cpp/locator.rb'
require 'tsc/after-end-reader.rb'

module SK
  module Lingo
    module Cpp
      class Baker < SK::Lingo::Baker
        include AfterEndReader
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
      module Cpp
        class BakerTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end

__END__

cpp:
  header_includes: |

  body_includes: |
    <iostream>
    <iomanip>

  extends: |

  initializes: |

  public_methods:

  protected_methods:

  private_methods:

  data: |

  factory:
    constructor(): |
    destructor(): |

  test:
    class_init: |
      CPPUNIT_TEST_SUITE(#{FULL_CLASS_NAME});
        CPPUNIT_TEST(testSimple);
      CPPUNIT_TEST_SUITE_END();

    header_includes: |
      <cppunit/TestFixture.h>
      <cppunit/extensions/HelperMacros.h>

    body_top: |
      CPPUNIT_TEST_SUITE_REGISTRATION(#{FULL_CLASS_NAME});

    header_bottom: |

    body_includes: |

    extends: |
      public CppUnit::TestFixture

    initializes: |

    public_methods:
      void setUp(): |
      void tearDown(): |
      void testSimple(): |
        CPPUNIT_ASSERT_EQUAL(true, false);

    protected_methods:

    private_methods:

    data: |

    factory:
