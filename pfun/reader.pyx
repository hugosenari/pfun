from functools import wraps

from .list cimport List, _list, Empty, Element
from trampoline cimport Done, Call
from monad cimport (
    _sequence as _sequence_, 
    _map_m as _map_m_, 
    Monad, wrap_t, 
    _filter_m as 
    _filter_m_, 
    _with_effect as 
    _with_effect_
)

cdef class Reader(Monad):
    cdef object run_r

    def run(self, context):
        return self._run(context)
    
    cdef object _run(self, object context):
        return self.run_r(context).run()

    def __cinit__(self, run_r):
        self.run_r = run_r
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef Reader _and_then(self, object f):
        return Reader.__new__(
            Reader,
            lambda context: Call(
                lambda: self.run_r(context).and_then(
                    lambda v: Call(lambda: (<Reader>f(v)).run_r(context))
                )
            )
        )

def wrap(value):
    return _wrap(value)

def ask():
    return _ask()

cdef Reader _ask():
    return Reader.__new__(Reader, lambda context: Done.__new__(Done, context))

def sequence(readers):
    return _sequence(readers)

cdef Reader _sequence(object readers):
    return _sequence_(<wrap_t>_wrap, readers)

def map_m(f, xs):
    return _map_m(f, xs)

cdef Reader _map_m(object f, object xs):
    return _map_m_(<wrap_t>_wrap, f, xs)

def filter_m(f, xs):
    return _filter_m(f, xs)

cdef Reader _filter_m(object f, object xs):
    return _filter_m_(<wrap_t>_wrap, f, xs)

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect_(<wrap_t>_wrap, g)
    return decorator

cdef Reader _wrap(object value):
    return Reader(lambda _: Done.__new__(Done, value))
