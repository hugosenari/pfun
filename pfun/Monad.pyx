from .list cimport List, Empty, _list

cdef class Functor:
    cdef Functor _map(self, object f):
        return NotImplemented

cdef class Monad(Functor):
    cdef Monad _and_then(self, object f):
        return NotImplemented

cdef Monad _sequence(wrap_t wrap, object monads):
    cdef List monads_
    
    if isinstance(monads, List):
        monads_ = monads
    else:
        monads_ = _list(monads)
    
    def combine(Monad r1, Monad r2):
        return r1._and_then(lambda l: r2._and_then(lambda e: wrap((<List>l)._prepend(e))))

    return monads_._reduce_r(combine, wrap(Empty()))

cdef Monad _map_m(wrap_t wrap, object mapper, object xs):
    ms = (mapper(x) for x in xs)
    return _sequence(wrap, ms)
