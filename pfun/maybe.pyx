from monad cimport Monad, _sequence as _sequence_, _map_m as _map_m_, _filter_m as _filter_m_, wrap_t


cdef class Maybe(Monad):
    pass

cdef class Just(Maybe):
    cdef object get

    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        return self._map(f)
    
    def __repr__(self):
        return f'Just({self.get})'
    
    cdef Maybe _map(self, object f):
        return Just(f(self.get))
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef Maybe _and_then(self, f):
        return f(self.get)


cdef class Nothing(Maybe):
    def map(self, f):
        return self._map(f)
    
    cdef Maybe _map(self, object f):
        return self
    
    def and_then(self, f):
        return self
    
    cdef Maybe _and_then(self, object f):
        return self
    
    def __repr__(self):
        return 'Nothing()'


def sequence(maybes):
    return _sequence(maybes)

cdef Maybe _wrap(object x):
    return Just(x)

cdef Maybe _sequence(object maybes):
    return _sequence_(<wrap_t>_wrap, maybes)