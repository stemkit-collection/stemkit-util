%include "std_string.i"
%include "std_vector.i"
%include "typemaps.i"

%module "SK::rt"

%{
#include <sk/rt/config/UprootLocator.h>
#include <sk/rt/config/CwdUprootLocator.h>
#include <sk/rt/config/HomeLocator.h>
#include <sk/rt/scope/Controller.h>
#include <sk/rt/Scope.h>

using sk::rt::config::StreamProcessor;
using sk::rt::config::NamedStreamOpener;

#include "LoggerAdaptor.h"

%}

namespace sk
{
  namespace util {
    %naturalvar String;
    class String;
  }
}

%typemaps_std_string(sk::util::String, char, SWIG_AsCharPtrAndSize, SWIG_FromCharPtrAndSize, %checkcode(STDSTRING));

%exception {
  try {
    $action
  }
  catch(const std::exception& exception) {
    rb_raise(rb_eRuntimeError, exception.what());
    throw;
  }
}

%ignore getClass;
%ignore *::SpotLocator::openStream;

%include <sk/rt/config/Locator.h>
%include <sk/rt/config/SpotLocator.h>
%include <sk/rt/config/UprootLocator.h>
%include <sk/rt/config/CwdUprootLocator.h>
%include <sk/rt/config/HomeLocator.h>

%ignore *::Controller::getAggregator;
%rename(load_xml_config) *::Controller::loadXmlConfig;

%include <sk/rt/scope/Controller.h>

%ignore *::Scope::error;
%ignore *::Scope::warning;
%ignore *::Scope::notice;
%ignore *::Scope::info;
%ignore *::Scope::debug;
%ignore *::Scope::detail;

%rename(property) *::Scope::getProperty;
%rename(has_property) *::Scope::hasProperty;
%predicate hasProperty;
%ignore *::LoggerAdaptor::LoggerAdaptor;

%include <sk/rt/Scope.h>
%include "LoggerAdaptor.h"

%extend sk::rt::Scope {
  ruby::LoggerAdaptor log() const {
    return ruby::LoggerAdaptor(*$self);
  }

  ruby::LoggerAdaptor log(const sk::util::String& label) const {
    return ruby::LoggerAdaptor(label, *$self);
  }
}

