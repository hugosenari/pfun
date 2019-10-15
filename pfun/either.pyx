from monad cimport Monad


cdef class Either(Monad):
    pass


cdef class Right(Either):
    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        return self._map(f)
    
    cdef Either _map(self, object f):
        return Right(f(self.get))
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef Either _and_then(self, object f):
        return f(self.get)


cdef class Left(Either):
    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        return self._map(f)
    
    cdef Either _map(self, object f):
        return self
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef Either _and_then(self, object f):
        return self