from functools import wraps
from typing import Generator

from .monad cimport (
    Monad, 
    _sequence, 
    _map_m, 
    _filter_m, 
    wrap_t, 
    _with_effect
)
from .trampoline cimport Trampoline, Call, Done

cdef class State(Monad):
    def __cinit__(self, run_s):
        self.run_s = run_s
    
    def map(self, f):
        return self._map(f)
    
    def run(self, state):
        return self._run(state)
    
    cdef object _run(self, object state):
        return (<Trampoline>self.run_s(state))._run()
    
    cdef State _map(self, object f):
        return State(
            lambda s: Call(lambda: 
                (<Trampoline>self.run_s(s))._map(
                    lambda vs: (f(vs[0]), vs[1])
                )
            )
        )
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef State _and_then(self, f):
        return State(lambda s: 
            Call(lambda: 
                (<Trampoline>self.run_s(s))._and_then(lambda vs: 
                    Call(lambda: 
                        (<State>f(vs[0])).run_s(vs[1])
                    )
                )
            )
        )

def wrap(x):
    return _wrap(x)

cdef State _wrap(object x):
    return State(lambda s: Done((x, s)))

def get():
    return _get()

cdef State _get():
    return State(lambda s: Done((s, s)))

def put(state):
    return _put(state)

cdef State _put(state):
    return State(lambda s: Done((None, state)))

def sequence(states):
    return _sequence(<wrap_t>_wrap, states)

def map_m(f, iterable):
    return _map_m(<wrap_t>_wrap, f, iterable)

def filter_m(f, iterable):
    return _filter_m(<wrap_t>_wrap, f, iterable)

# hack to make it possible to
# import the type alias from .pyi
States = Generator

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect(<wrap_t>_wrap, g)
    return decorator