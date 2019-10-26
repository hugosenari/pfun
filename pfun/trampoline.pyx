from typing import Generator
from functools import wraps

from .monad cimport (
    Monad, 
    _sequence, 
    _map_m, 
    _filter_m, 
    wrap_t, 
    _with_effect
)

cdef class Trampoline(Monad):
    def and_then(self, f):
        return self._and_then(f)
    
    def map(self, f):
        return self._map(f)
    
    cdef Trampoline _map(self, object f):
        return self._and_then(lambda v: Done(f(v)))
    
    def run(self):
        return self._run()
    
    cdef object _run(self):
        cdef Trampoline trampoline
        trampoline = self
        while not isinstance(trampoline, Done):
            if isinstance(trampoline, Call):
                trampoline = (<Call>trampoline).thunk()
            else:
                sub1 = (<AndThen>trampoline).sub
                cont1 = (<AndThen>trampoline).cont
                if isinstance(sub1, Done):
                    trampoline = cont1((<Done>sub1).result)
                elif isinstance(sub1, Call):
                    trampoline = (<Call>sub1).thunk().and_then(cont1)
                else:
                    sub2 = (<AndThen>sub1).sub
                    cont2 = (<AndThen>sub1).cont
                    trampoline = sub2.and_then(cont2).and_then(cont1)
        return (<Done>trampoline).result


    cdef Trampoline _and_then(self, object f):
        return AndThen.__new__(AndThen, self, f)


cdef class Done(Trampoline):
    def __eq__(self, other):
        return isinstance(other, Done) and other.result == self.result
    def __cinit__(self, result):
        self.result = result

cdef class Call(Trampoline):
    def __cinit__(self, thunk):
        self.thunk = thunk

cdef class AndThen(Trampoline):
    def __cinit__(self, sub, cont):
        self.sub = sub
        self.cont = cont

    cdef Trampoline _and_then(self, object f):
        return AndThen.__new__(
            AndThen,
            self.sub,
            lambda x: Call(lambda: self.cont(x).and_then(f))  # type: ignore
        )
    
cdef Trampoline _wrap(object value):
    return Done(value)

def sequence(trampolines):
    return _sequence(<wrap_t>_wrap, trampolines)

def map_m(f, iterable):
    return _map_m(<wrap_t>_wrap, f, iterable)

def filter_m(f, iterable):
    return _filter_m(<wrap_t>_wrap, f, iterable)

# hack to make it possible to
# import the type alias from .pyi
Trampolines = Generator

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect(<wrap_t>_wrap, g)
    return decorator
