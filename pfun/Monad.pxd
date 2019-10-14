cdef class Functor:
    cdef Functor _map(self, object f)

cdef class Monad(Functor):
    cdef Monad _and_then(self, object f)

ctypedef Monad (*wrap_t)(object)

cdef Monad _sequence(wrap_t wrap, object monads)
cdef Monad _map_m(wrap_t wrap, object mapper, object xs)
cdef Monad _filter_m(wrap_t wrap, object p, object xs)
cdef Monad _with_effect(wrap_t wrap, object g)
