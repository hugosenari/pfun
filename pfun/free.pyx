from typing import Generator
from functools import wraps

from .state cimport State, _get
from .monad cimport (
    Functor,
    Monad, 
    _sequence, 
    _map_m, 
    _filter_m, 
    wrap_t, 
    _with_effect
)
from .curry import curry


ctypedef fused FreeOrElement:
    Free
    FreeInterpreterElement

cdef class FreeInterpreter:
    """
    An interpreter to map a ``Free`` structure into a `D` from a `C`.
    """
    cpdef State interpret(self, FreeOrElement root):
        """
        Run the interpreter on the root element recursively

        :param root: The root interpreter element
        :return: The result of interpreting ``root``
        """
        return root.accept(self)

    cpdef State interpret_more(self, More more):
        return more.k.accept(self)

    cpdef State interpret_done(self, Done done):
        return _get()


cdef class FreeInterpreterElement(Functor):
    """
    An element in a ``Free`` structure that can be interepreted
    """
    cpdef State accept(self, FreeInterpreter interpreter):
        """
        Interpret this element

        :param interpreter: The interpreter to apply to this element
        :return: The result of using ``interpreter` to interpret this element
        """
        pass


cdef class Free(Monad):
    """
    The "Free" monad
    """
    cpdef Free and_then(
        self, object f
    ):
        pass

    def map(self, f):
        return self._map(f)
    
    cdef Free _map(self, object f):
        return self.and_then(lambda v: Done(f(v)))


cdef class Done(Free):
    """
    Pure ``Free`` value
    """
    cdef readonly object get

    def __cinit__(self, get):
        self.get = get
    
    def __eq__(self, other):
        return isinstance(other, Done) and other.get == self.get

    cpdef Free and_then(self, object f):
        """
        Apply ``f`` to the value wrapped in this ``Done``

        :param f: The function to apply to the value wrapped in this ``Done``
        :return: The result of applying ``f`` to the value in this ``Done``
        """
        return f(self.get)

    cpdef State accept(self, FreeInterpreter interpreter):
        """
        Run an interpreter on this ``Done``

        :param interpreter: The interpreter to run on on this ``Done`` instance
        :return: The result of interpreting this ``Done`` instance
        """
        return interpreter.interpret_done(self)


cdef class More(Free):
    """
    A ``Free`` value wrapping a `Functor` value
    """
    cdef Functor k

    def __cinit__(self, k):
        self.k = k

    def and_then(self, f):
        """
        Apply ``f`` to the value wrapped in the functor of this ``More``

        :param f: The function to apply to the functor value
        :return: The result of applying ``f`` to the functor of this ``More``
        """
        return self._and_then(f)
    
    cdef Free _and_then(self, object f):
        return More(self.k.map(lambda v: v.and_then(f)))

    cpdef State accept(self, FreeInterpreter interpreter):
        """
        Run an interpreter on this ``More``

        :param interepreter: The intepreter to run on this ``More`` instance
        :return: The result of running ``interpreter`` on this ``More``
        """
        return interpreter.interpret_more(self)


cdef Free wrap(object v):
    return Done(v)

@curry
def map_m(f, iterable):
    """
    Map each in element in ``iterable`` to
    a :class:`Free` by applying ``f``,
    combine the elements by ``and_then``
    from left to right and collect the results

    :param f: Function to map over ``iterable``
    :param iterable: Iterable to map ``f`` over
    :return: ``f`` mapped over ``iterable`` and combined from left to right.
    """
    return _map_m(<wrap_t>wrap, f, iterable)


def sequence(iterable):
    """
    Evaluate each ``Free`` in `iterable` from left to right
    and collect the results

    :param iterable: The iterable to collect results from
    :returns: ``Free`` of collected results
    """
    return _sequence(<wrap_t>wrap, iterable)


@curry
def filter_m(f, iterable):
    """
    Map each element in ``iterable`` by applying ``f``,
    filter the results by the value returned by ``f``
    and combine from left to right.

    :param f: Function to map ``iterable`` by
    :param iterable: Iterable to map by ``f``
    :return: `iterable` mapped and filtered by `f`
    """
    _filter_m(<wrap_t>wrap, f, iterable)

Frees = Generator


def with_effect(f):
    """
    Decorator for functions that
    return a generator of frees and a final result.
    Iteraters over the yielded frees and sends back the
    unwrapped values using "and_then"

    :example:
    >>> from typing import Any
    >>> @with_effect
    ... def f() -> Frees[int, int, Any, Any]:
    ...     a = yield Done(2)
    ...     b = yield Done(2)
    ...     return a + b
    >>> f()
    Done(4)

    :param f: generator function to decorate
    :return: `f` decorated such that generated :class:`Free` \
        will be chained together with `and_then`
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect(<wrap_t>wrap, g)
    return decorator
