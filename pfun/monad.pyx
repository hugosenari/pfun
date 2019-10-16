from .list cimport List, Empty, _list
from either cimport Right, Left

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

    return monads_._reduce_r(combine, wrap(Empty())).map(tuple)

cdef Monad _map_m(wrap_t wrap, object mapper, object xs):
    ms = (mapper(x) for x in xs)
    return _sequence(wrap, ms)

cdef Monad _filter_m(wrap_t wrap, object p, object xs):
    cdef List xs_
    if isinstance(xs, List):
        xs_ = xs
    else:
        xs_ = _list(xs)
    
    def combine(Monad m1, object x):
        return m1._and_then(lambda l: (<Monad>p(x))._and_then(lambda b: wrap((<List> l)._prepend(x) if b else l)))
    
    return xs_._reduce_r(combine, wrap(Empty())).map(tuple)

cdef Monad _with_effect(wrap_t wrap, object g):
    def cont(object v):
        try:
            return (<Monad>g.send(v))._and_then(cont)
        except StopIteration as e:
            return wrap(e.value)

    try:
        m = <Monad>next(g)
        return m._and_then(cont)
    except StopIteration as e:
        return wrap(e.value)

cdef Monad _with_effect_tail_rec(wrap_t wrap, object g, tail_rec_t tail_rec):
        cdef Monad m
        def cont(v):
            try:
                return (<Monad>g.send(v))._map(Left)
            except StopIteration as e:
                return wrap(Right(e.value))

        try:
            m = next(g)
            return m._and_then(lambda v: tail_rec(cont, v))
        except StopIteration as e:
            return wrap(e.value)
