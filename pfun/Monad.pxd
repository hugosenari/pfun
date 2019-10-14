from .list cimport List

cdef class Functor:
    cdef Functor _map(self, object f)

cdef class Monad(Functor):
    cdef Monad _and_then(self, object f)

ctypedef Monad (*wrap_t)(object)

cdef Monad _sequence(wrap_t wrap, object monads)
cdef Monad _map_m(wrap_t wrap, object mapper, object monads)
