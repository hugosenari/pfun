from typing import TypeVar, Generic, Union

from trampoline cimport Done, Call, Trampoline

cdef class List:
    def __pow__(other, self, _):
        if isinstance(self, List):
            return (<List>self)._prepend(other)
        return NotImplemented
    
    def __add__(self, other):
        return (<List>self)._extend(other)

    def prepend(self, other):
        return self._prepend(other)
    
    cdef List _prepend(self, object other):
        return Element(other, self)
    
    def map(self, f):
        return self._map(f)
    
    cdef List _map(self, object f):
        return list_(tuple(f(e) for e in self))
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef List _and_then(self, object f):
        cdef List result
        result = Empty()
        for e in self:
            result = result._extend(<List>f(e))
        return result

    def filter(self, f):
        return self._filter(f)
    
    cdef List _filter(self, object f):
        return list_(tuple(e for e in self if f(e)))
    
    def reduce(self, f, init):
        return self._reduce(f, init)
    
    cdef object _reduce(self, object f, object init):
        cdef object result
        result = init
        for e in self:
            result = f(result, e)
        return result
    
    def reduce_r(self, f, init):
        return self._reduce_r(f, init)
    
    cdef object _reduce_r(self, object f, object init):
        def go(List l):
            if isinstance(l, Empty):
                return Done(init)
            return Call(lambda: 
                go((<Element>l).tail).map(
                    lambda v: f(v, (<Element> l).head)
                )
            )
        return (<Trampoline>go(self))._run()
    
    def zip(self, other):
        return zip(self, other)
    
    def extend(self, other):
        return self._extend(other)
    
    cdef List _extend(self, List other):
        return list_(tuple(self) + tuple(other))

    def __len__(self):
        return self.length
    
    def __iter__(self):
        return self._iter()
    
    cdef object _iter(self):
        def _():
            cdef List l
            l = self
            while isinstance(l, Element):
                yield (<Element>l).head
                l = (<Element>l).tail
        return iter(_())

    def __repr__(self):
        return self._repr()

    cdef str _repr(self):
        cdef str elems_repr
        elems_repr = ', '.join(self._map(repr))
        return 'List(' + elems_repr + ')'


cdef class Empty(List):
    def __cinit__(self):
        self.length = 0


def list_(xs):
    return _list(xs)


cdef List _list(object xs):
    cdef List l
    l = Empty()
    for x in reversed(tuple(xs)):
        l = l.prepend(x)
    return l


cdef class Element(List):
    def __cinit__(self, object head, List tail):
        self.head = head
        self.tail = tail
        self.length = tail.length + 1
