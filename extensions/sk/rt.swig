%include "std_string.i"
%include "std_vector.i"
%include "typemaps.i"

%module "SK::rt"

%{
#include <sk/rt/config/UprootLocator.h>

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
%ignore openStream;

%include <sk/rt/config/SpotLocator.h>
%include <sk/rt/config/UprootLocator.h>

