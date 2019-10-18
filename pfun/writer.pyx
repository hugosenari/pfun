from functools import wraps
from typing import Generator

from .monad cimport (
    Monad, 
    _sequence, 
    _map_m, 
    _filter_m, 
    wrap_t, 
    _with_effect
)
from .monoid import empty, append

cdef class Writer(Monad):
    """
    Represents a value
    along with a monoid value that is accumulated as
    an effect
    """
    cdef readonly object get
    cdef readonly object monoid

    def __cinit__(self, get, monoid):
        self.get = get
        self.monoid = monoid

    def and_then(self, f):
        """
        Pass the value in this value/monoid pair to ``f``,
        and then combine the resulting monoid with the monoid in this pair

        :example:
        >>> Writer(1, ['first element']).and_then(
        ...     lambda i: Writer(i + 1, ['second element'])
        ... )
        Writer(2, ['first element', 'second element'])

        :param f: Function to pass the value to
        :return: :class:`Writer` with result of
                 passing the value in this :class:`Writer`
                 to ``f``, and appending the monoid in this
                 instance with the result of ``f``
        """
        return self._and_then(f)
    
    cdef Writer _and_then(self, object f):
        w = f(self.get)
        if w.monoid is None and self.monoid is None:
            monoid = None
        elif w.monoid is None:
            monoid = append(self.monoid, empty(self.monoid))
        elif self.monoid is None:
            monoid = append(empty(w.monoid), w.monoid)
        else:
            monoid = append(self.monoid, w.monoid)
        return Writer(w.get, monoid)

    def __eq__(self, other):
        if not isinstance(other, Writer):
            return False
        return other.get == self.get and other.monoid == self.monoid

    def map(self, f: 'Callable[[A], B]') -> 'Writer[B, M]':
        """
        Map the value/monoid pair in this :class:`Writer`

        :example:
        >>> Writer('value', []).map(lambda v, m: ('new value', ['new monoid']))
        Writer('new value', ['new monoid'])

        :param f: the function to map the value and
                  monoid in this :class:`Writer`
        :return: :class:`Writer` with value and monoid mapped by ``f``
        """
        return self._map(f)
    
    cdef Writer _map(self, object f):
        return Writer(f(self.get), self.monoid)

    def __repr__(self):
        a_repr = repr(self.get)
        m_repr = repr(self.monoid)
        return f'Writer({a_repr}, {m_repr})'

    def __iter__(self):
        return iter((self.get, self.monoid))


def wrap(a, m=None):
    """
    Put a value in a :class:`Writer` context

    :example:
    >>> value(1)
    Writer(1, ...)
    >>> value(1, ['some monoid'])
    Writer(1, ['some monoid'])

    :param a: The value to put in the :class:`Writer` context
    :param m: Optional monoid to associate with ``a``
    :return: :class:`Writer` with ``a`` and optionally ``m``
    """
    return _wrap(a, m)

cdef Writer _wrap(object a, object m=None):
    return Writer(a, m)


def tell(m):
    """
    Create a Writer with a monoid ``m`` and unit value

    :example:
    >>> tell(
    ...     ['monoid value']
    ... ).and_then(
    ...     lambda _: tell(['another monoid value'])
    ... )
    Writer(None, ['monoid value', 'another monoid value'])

    :param m: the monoid value
    :return: Writer with unit value and monoid value ``m``
    """
    return _tell(m)

cdef Writer _tell(object m):
    return Writer(None, m)

def sequence(writers):
    return _sequence(<wrap_t>_wrap, writers)

def map_m(f, iterable):
    return _map_m(<wrap_t>_wrap, f, iterable)

def filter_m(f, iterable):
    return _filter_m(<wrap_t>_wrap, f, iterable)

# hack to make it possible to
# import the type alias from .pyi
Writers = Generator

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect(<wrap_t>_wrap, g)
    return decorator
