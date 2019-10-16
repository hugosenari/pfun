from functools import wraps
from typing import Union, Generator

from monad cimport (
    Monad, 
    _sequence as _sequence_, 
    _map_m as _map_m_, 
    _filter_m as _filter_m_, 
    wrap_t, 
    _with_effect_tail_rec, 
    tail_rec_t
)

from .list cimport List, _list


cdef class _Either(Monad):
    pass


cdef class Right(_Either):
    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        return self._map(f)
    
    cdef _Either _map(self, object f):
        return Right(f(self.get))
    
    def __eq__(self, other):
        return isinstance(other, Right) and self.get == other.get
    
    def __bool__(self):
        return True
    
    def or_else(self, default):
        return self.get
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef _Either _and_then(self, object f):
        return f(self.get)


cdef class Left(_Either):
    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        return self._map(f)
    
    cdef _Either _map(self, object f):
        return self
    
    def __eq__(self, other):
        return isinstance(other, Left) and self.get == other.get
    
    def __bool__(self):
        return False
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef _Either _and_then(self, object f):
        return self
    
    def or_else(self, default):
        return default

def tail_rec(f, init):
    return _tail_rec(f, init)


cdef _Either _tail_rec(object f, object init):
    cdef _Either outer_either
    cdef _Either inner_either
    outer_either = f(init)
    if isinstance(outer_either, Left):
        return outer_either
    inner_either = outer_either.get
    while isinstance(inner_either, Left):
        outer_either = f(inner_either.get)
        if isinstance(outer_either, Left):
            return outer_either
        inner_either = outer_either.get
    return inner_either

def either(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        return Right(f(*args, **kwargs))
    return decorator

def flatten(maybes):
    return _flatten(maybes)

cdef List _flatten(object maybes):
    return _list(m.get for m in maybes if isinstance(m, Right))

def sequence(eithers):
    return _sequence(eithers)

cdef _Either _wrap(object value):
    return Right(value)

cdef _Either _sequence(object eithers):
    return _sequence_(<wrap_t>_wrap, eithers)

def map_m(f, iterable):
    return _map_m(f, iterable)

cdef _Either _map_m(object f, object xs):
    return _map_m_(<wrap_t>_wrap, f, xs)

def filter_m(f, iterable):
    return _filter_m_(<wrap_t>_wrap, f, iterable)

# hack to make it possible to
# import the type alias from .pyi
Either = Union
Eithers = Generator

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect_tail_rec(<wrap_t>_wrap, g, <tail_rec_t>_tail_rec)
    return decorator
