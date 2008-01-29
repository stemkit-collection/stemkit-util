%include "std_string.i"
%include "std_vector.i"
%include "typemaps.i"

%module "SK::rt"

%{
#include <sk/rt/config/UprootLocator.h>
#include <sk/rt/scope/Controller.h>

using sk::rt::config::StreamProcessor;
using sk::rt::config::NamedStreamOpener;

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
%ignore *::Controller::getAggregator;

%rename(load_xml_config) *::Controller::loadXmlConfig;

%include <sk/rt/config/Locator.h>
%include <sk/rt/config/SpotLocator.h>
%include <sk/rt/config/UprootLocator.h>
%include <sk/rt/scope/Controller.h>

