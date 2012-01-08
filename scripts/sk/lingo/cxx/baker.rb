=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/lingo/cpp/baker.rb'

module SK
  module Lingo
    module Cxx
      class Baker < SK::Lingo::Cpp::Baker
        def accept_by_extension(item)
          case item.extension
            when 'hxx'
              proc {
                header item, :hxx
              }

            when 'cxx'
              proc {
                header item, :cxx
              }
          end
        end

        def accept_default(item)
          proc {
            header item, :hxx, 'hxx'
            header item, :cxx, 'cxx'
          }
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end
      end
    end
  end
end

__END__

cpp:
  default:
    hxx:
      indent: 0
      content:
        -
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}

        -
          namespace: true
          content: |-
            template<typename T>
            class #{class_name}
            {
              public:
                #{class_name}();
                ~#{class_name}();

                void process(T& object);

              private:
                #{class_name}(const #{class_name}<T>& other);
                #{class_name}<T>& operator = (const #{class_name}<T>& other);
            };

        -
          content: |-
            #endif /* #{class_tag} */

    cxx:
      indent: 0
      content:
        -
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}

        -
          content: |-
            #include #{class_reference(:hxx)}

            template<typename T>
            #{full_class_name}<T>::
            #{class_name}()
            {
            }

            template<typename T>
            #{full_class_name}<T>::
            ~#{class_name}()
            {
            }

            template<typename T>
            void
            #{full_class_name}<T>::
            process(T& object)
            {
            }

        -
          content: |-
            #endif /* #{class_tag} */

  sk-default:
    hxx:
      indent: 0
      content:
        -
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}

        -
          namespace: true
          content: |-
            template<typename T>
            class #{class_name}
            {
              public:
                #{class_name}();
                ~#{class_name}();

                void process(T& object);

              private:
                #{class_name}(const #{class_name}<T>& other);
                #{class_name}<T>& operator = (const #{class_name}<T>& other);
            };

        -
          content: |-
            #endif /* #{class_tag} */

    cxx:
      indent: 0
      content:
        -
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}

        -
          content: |-
            #include #{class_reference(:hxx)}

            template<typename T>
            #{full_class_name}<T>::
            #{class_name}()
            {
            }

            template<typename T>
            #{full_class_name}<T>::
            ~#{class_name}()
            {
            }

            template<typename T>
            void
            #{full_class_name}<T>::
            process(T& object)
            {
            }

        -
          content: |-
            #endif /* #{class_tag} */
