from functools import wraps

from monad cimport Monad, _sequence as _sequence_, _map_m as _map_m_, _filter_m as _filter_m_, wrap_t, _with_effect_tail_rec, tail_rec_t
from either cimport Left, Right, Either
from .list cimport _list, List


cdef class Maybe(Monad):
    pass

cdef class Just(Maybe):
    cdef readonly object get

    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        return self._map(f)
    
    def __repr__(self):
        return f'Just({self.get})'
    
    def __bool__(self):
        return True
    
    def __eq__(self, other):
        return isinstance(other, Just) and self.get == other.get
    
    cdef Maybe _map(self, object f):
        return Just(f(self.get))
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef Maybe _and_then(self, f):
        return f(self.get)

    def or_else(self, default):
        return self._or_else(default)
    
    cdef object _or_else(self, object default):
        return self.get


cdef class Nothing(Maybe):
    def map(self, f):
        return self._map(f)
    
    cdef Maybe _map(self, object f):
        return self
    
    def and_then(self, f):
        return self
    
    cdef Maybe _and_then(self, object f):
        return self
    
    def or_else(self, default):
        return self._or_else(default)
    
    cdef object _or_else(self, object default):
        return default
    
    def __repr__(self):
        return 'Nothing()'
    
    def __eq__(self, other):
        return isinstance(other, Nothing)
    
    def __bool__(self):
        return False

cdef Maybe _wrap(object x):
    return Just(x)

def maybe(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        try:
            return Just(f(*args, **kwargs))
        except:
            return Nothing()
    return decorator

def flatten(maybes):
    return _flatten(maybes)

cdef List _flatten(object maybes):
    return _list(m.get for m in maybes if isinstance(m, Just))

def sequence(maybes):
    return _sequence(maybes)

cdef Maybe _sequence(object maybes):
    return _sequence_(<wrap_t>_wrap, maybes)

def map_m(f, xs):
    return _map_m(f, xs)

cdef Maybe _map_m(object f, object xs):
    return _map_m_(<wrap_t>_wrap, f, xs)

def filter_m(f, xs):
    return _filter_m_(<wrap_t>_wrap, f, xs)


def tail_rec(f, init):
    return _tail_rec(f, init)

cdef Maybe _tail_rec(object f, object init):
    cdef Maybe maybe
    cdef Either either
    maybe = f(init)
    if isinstance(maybe, Nothing):
        return maybe
    either = maybe.get
    while isinstance(either, Left):
        maybe = f(either.get)
        if isinstance(maybe, Nothing):
            return maybe
        either = maybe.get
    return Just(either.get)

# hack to make it possible to
# import the type alias from .pyi
Maybes = None

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect_tail_rec(<wrap_t>_wrap, g, <tail_rec_t>_tail_rec)
    return decorator
