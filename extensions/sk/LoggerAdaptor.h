/*  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
 *  
 *  Distributed under the MIT Licence.
 *  This is free software. See 'LICENSE' for details.
 *  You must read and accept the license prior to use.
*/

#ifndef _RUBY_LOGGERADAPTOR_
#define _RUBY_LOGGERADAPTOR_

#include <sk/util/String.h>
#include <sk/rt/Scope.h>

namespace ruby {
  class LoggerAdaptor
  {
    public:
      LoggerAdaptor(const sk::rt::Scope& scope)
        : _label(sk::util::String::EMPTY), _scope(scope)  {}

      LoggerAdaptor(const sk::util::String& label, const sk::rt::Scope& scope)
        : _labelStore(label), _label(_labelStore), _scope(scope)  {}

      void error(const sk::util::String& message) const {
        _scope.error(_label) << message;
      }
      
      void warning(const sk::util::String& message) const {
        _scope.warning(_label) << message;
      }

      void notice(const sk::util::String& message) const {
        _scope.notice(_label) << message;
      }

      void info(const sk::util::String& message) const {
        _scope.info(_label) << message;
      }

      void debug(const sk::util::String& message) const {
        _scope.debug(_label) << message;
      }

      void detail(const sk::util::String& message) const {
        _scope.detail(_label) << message;
      }

    private:
      const sk::util::String _labelStore;
      const sk::util::String& _label;

      const sk::rt::Scope& _scope;
  };
}

#endif /* _RUBY_LOGGERADAPTOR_ */
