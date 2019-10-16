from functools import wraps
from typing import Union, Generator

from monad cimport Monad, _sequence as _sequence_, _map_m as _map_m_, _filter_m as _filter_m_, wrap_t, _with_effect_tail_rec, tail_rec_t
from either cimport Left, Right, _Either
from .list cimport _list, List


cdef class _Maybe(Monad):
    pass

cdef class Just(_Maybe):
    """
    Represents the result of a succesful computation

    """
    cdef readonly object get

    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        """
        Map the result of a possibly failed computation

        :example:
        >>> f = lambda i: Just(1 / i) if i != 0 else Nothing()
        >>> Just(2).and_then(f).map(str)
        Just('0.5')
        >>> Just(0).and_then(f).map(str)
        Nothing()

        :type f: Callable[[A], B]
        :param f: Function to apply to the result
        :return: :class:`Just` wrapping result of type B if the computation was
        :rtype: Maybe[B]

        """
        return self._map(f)
    
    def __repr__(self):
        return f'Just({self.get})'
    
    def __bool__(self):
        return True
    
    def __eq__(self, other):
        return isinstance(other, Just) and self.get == other.get
    
    cdef _Maybe _map(self, object f):
        return Just(f(self.get))
    
    def and_then(self, f):
        """
        Chain together functional calls, carrying along the state of the
        computation that may fail.
        
        :example:
        >>> f = lambda i: Just(1 / i) if i != 0 else Nothing()
        >>> Just(2).and_then(f)
        Just(0.5)
        >>> Just(0).and_then(f)
        Nothing()

        :type f: Callable[[A], Maybe[B]]
        :param f: the function to call
        :return: :class:`Just` wrapping a value of type B if \
        the computation was successful, :class:`Nothing` otherwise.
        :rtype: Maybe[B]
        """
        return self._and_then(f)
    
    cdef _Maybe _and_then(self, f):
        return f(self.get)

    def or_else(self, default):
        """
        Try to get the result of the possibly failed computation if it was
        successful.

        :example:
        >>> Just(1).or_else(2)
        1
        >>> Nothing().or_else(2)
        2

        :type default: A
        :param default: Value to return if computation has failed
        :return: The result wrapped by this Just
        :rtype: A

        """
        return self._or_else(default)
    
    cdef object _or_else(self, object default):
        return self.get


cdef class Nothing(_Maybe):
    """
    Represents the result of a failed computation
    """
    def map(self, f):
        """
        Map the result of a possibly failed computation

        :example:
        >>> f = lambda i: Just(1 / i) if i != 0 else Nothing()
        >>> Just(2).and_then(f).map(str)
        Just('0.5')
        >>> Just(0).and_then(f).map(str)
        Nothing()

        :type f: Callable[[A], B]
        :param f: Function to apply to the result
        :return: :class:`Just` wrapping result of type B if the computation was
        :rtype: Maybe[B]

        """
        return self._map(f)
    
    cdef _Maybe _map(self, object f):
        return self
    
    def and_then(self, f):
        """
        Chain together functional calls, carrying along the state of the
        computation that may fail.
        
        :example:
        >>> f = lambda i: Just(1 / i) if i != 0 else Nothing()
        >>> Just(2).and_then(f)
        Just(0.5)
        >>> Just(0).and_then(f)
        Nothing()

        :type f: Callable[[A], Maybe[B]]
        :param f: the function to call
        :return: :class:`Just` wrapping a value of type B if \
        the computation was successful, :class:`Nothing` otherwise.
        :rtype: Maybe[B]
        """
        return self
    
    cdef _Maybe _and_then(self, object f):
        return self
    
    def or_else(self, default):
        """
        Try to get the result of the possibly failed computation if it was
        successful.

        :example:
        >>> Just(1).or_else(2)
        1
        >>> Nothing().or_else(2)
        2

        :type default: A
        :param default: Value to return if computation has failed
        :return: the default value
        :rtype: A

        """
        return self._or_else(default)
    
    cdef object _or_else(self, object default):
        return default
    
    def __repr__(self):
        return 'Nothing()'
    
    def __eq__(self, other):
        return isinstance(other, Nothing)
    
    def __bool__(self):
        return False

cdef _Maybe _wrap(object x):
    return Just(x)

def maybe(f):
    """
    Wrap a function that may raise an exception with a :class:`Maybe`.
    Can also be used as a decorator. Useful for turning
    any function into a monadic function

    :example:
    >>> to_int = maybe(int)
    >>> to_int("1")
    Just(1)
    >>> to_int("Whoops")
    Nothing()

    :type f: Callable[..., A]
    :param f: Function to wrap
    :return: f wrapped with a :class:`Maybe`
    :rtype: Callable[..., Maybe[A]]
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        try:
            return Just(f(*args, **kwargs))
        except:
            return Nothing()
    return decorator

def flatten(maybes):
    """
    Extract value from each :class:`Maybe`, ignoring
    elements that are :class:`Nothing`

    :type maybes: Iterable[Maybe[A]]
    :param maybes: Seqence of :class:`Maybe`
    :return: :class:`List` of unwrapped values
    :rtype: List[A]
    """
    return _flatten(maybes)

cdef List _flatten(object maybes):
    return _list(m.get for m in maybes if isinstance(m, Just))

def sequence(maybes):
    """
    Evaluate each :class:`Maybe` in `iterable` from left to right
    and collect the results

    :example:
    >>> sequence([Just(v) for v in range(3)])
    Just(List(0, 1, 2))

    :type maybes: Iterable[Maybe[A]]
    :param maybes: The iterable to collect results from
    :return: ``Maybe`` of collected results
    :rtype: Maybe[List[A]]
    """
    return _sequence(maybes)

cdef _Maybe _sequence(object maybes):
    return _sequence_(<wrap_t>_wrap, maybes)

def map_m(f, iterable):
    """
    Map each in element in ``iterable`` to
    an :class:`Maybe` by applying ``f``,
    combine the elements by ``and_then``
    from left to right and collect the results

    :example:
    >>> map_m(Just, range(3))
    Just(List(0, 1, 2))

    :type f: Callable[[A], Maybe[A]]
    :param f: Function to map over ``iterable``
    :type iterable: Iterable[A]
    :param iterable: Iterable to map ``f`` over
    :return: ``f`` mapped over ``iterable`` and combined from left to right.
    :rtype: Maybe[List[A]]
    """
    return _map_m(f, iterable)

cdef _Maybe _map_m(object f, object xs):
    return _map_m_(<wrap_t>_wrap, f, xs)

def filter_m(f, iterable):
    """
    Map each element in ``iterable`` by applying ``f``,
    filter the results by the value returned by ``f``
    and combine from left to right.

    :example:
    >>> filter_m(lambda v: Just(v % 2 == 0), range(3))
    Just(List(0, 2))

    :type f: Callable[[A], Maybe[bool]]
    :param f: Function to map ``iterable`` by
    :param iterable: Iterable to map by ``f``
    :return: `iterable` mapped and filtered by `f`
    :rtype: Maybe[List[A]]
    """
    return _filter_m_(<wrap_t>_wrap, f, iterable)


def tail_rec(f, init):
    """
    Run a stack safe recursive monadic function `f`
    by calling `f` with :class:`Left` values
    until a :class:`Right` value is produced

    :example:
    >>> from pfun.either import Left, Right, Either
    >>> def f(i: str) -> Maybe[Either[int, str]]:
    ...     if i == 0:
    ...         return Just(Right('Done'))
    ...     return Just(Left(i - 1))
    >>> tail_rec(f, 5000)
    Just('Done')

    :type f: Callable[B, Maybe[Either[B, A]]]
    :param f: function to run "recursively"
    :type init: B
    :param init: initial argument to `f`
    :return: result of `f`
    :rtype: Maybe[A]
    """
    return _tail_rec(f, init)

cdef _Maybe _tail_rec(object f, object init):
    cdef _Maybe maybe
    cdef _Either either
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
Maybe = Union
Maybes = Generator

def with_effect(f):
    """
    Decorator for functions that
    return a generator of maybes and a final result.
    Iteraters over the yielded maybes and sends back the
    unwrapped values using "and_then"

    :example:
    >>> @with_effect
    ... def f() -> Maybes[int, int]:
    ...     a = yield Just(2)
    ...     b = yield Just(2)
    ...     return a + b
    >>> f()
    Just(4)

    :type f: Callable[..., Maybes[A, B]]
    :param f: generator function to decorate
    :return: `f` decorated such that generated :class:`Maybe` \
        will be chained together with `and_then`
    :rtype: Callable[..., Maybe[B]]
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect_tail_rec(<wrap_t>_wrap, g, <tail_rec_t>_tail_rec)
    return decorator
