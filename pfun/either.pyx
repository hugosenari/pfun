from functools import wraps
from typing import Union, Generator

from .monad cimport (
    Monad, 
    _sequence as _sequence_, 
    _map_m as _map_m_, 
    _filter_m as _filter_m_, 
    wrap_t, 
    _with_effect_tail_rec, 
    tail_rec_t
)

from .list cimport List, _list


cdef class _Either(Monad):
    pass


cdef class Right(_Either):
    """
    Represents the ``Right`` case of ``Either``
    """

    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        """
        Map the result of this either computation
        
        :example:
        >>> f = lambda i: Right(1 / i) if i != 0 else Left('i was 0').map(str)
        >>> Right(1).and_then(f).map(str)
        Right('0.5')
        >>> Ok(0).and_then(f).map(str)
        Left('i was 0')

        :type f: Callable[[A], C]
        :param f: Function to apply to the result
        :return: :class:`Right` wrapping result of type C  \
                 if the computation was if this is a ``Right`` value, \
                 :class:`Left` of type B otherwise
        :rtype: Either[B, C]
        """
        return self._map(f)
    
    cdef _Either _map(self, object f):
        return Right(f(self.get))
    
    def __eq__(self, other):
        return isinstance(other, Right) and self.get == other.get
    
    def __repr__(self):
        return f'Right({self.get})'
    
    def __bool__(self):
        return True
    
    def or_else(self, default):
        """
        Try to get the result of this either computation, return default
        if this is a ``Left`` value

        :example:
        >>> Right(1).or_else(2)
        1
        >>> Left(1).or_else(2)
        2
        
        :type default: A
        :param default: Value to return if this is a ``Left`` value
        :return: Result of computation if this is a ``Right`` value, \
                 default otherwise
        """
        return self.get
    
    def and_then(self, f):
        """
        Chain together functions of either computations, keeping
        track of whether or not any of them have failed
        :example:

        >>> f = lambda i: Right(1 / i) if i != 0 else Left('i was 0')
        >>> Right(1).and_then(f)
        Right(1.0)
        >>> Right(0).and_then(f)
        Left('i was 0')

        :type f: Callable[[A], Either[B, C]]
        :param f: The function to call
        :return: :class:`Right` of type A if \
        the computation was successful, :class:`Left` of type B otherwise.
        :rtype: Either[B, C]
        """
        return self._and_then(f)
    
    cdef _Either _and_then(self, object f):
        return f(self.get)


cdef class Left(_Either):
    def __cinit__(self, get):
        self.get = get
    
    def map(self, f):
        """
        Map the result of this either computation
        
        :example:
        >>> f = lambda i: Right(1 / i) if i != 0 else Left('i was 0').map(str)
        >>> Right(1).and_then(f).map(str)
        Right('0.5')
        >>> Ok(0).and_then(f).map(str)
        Left('i was 0')

        :type f: Callable[[A], C]
        :param f: Function to apply to the result
        :return: :class:`Right` wrapping result of type C  \
                 if the computation was if this is a ``Right`` value, \
                 :class:`Left` of type B otherwise
        :rtype: Either[B, C]
        """
        return self._map(f)
    
    cdef _Either _map(self, object f):
        return self
    
    def __eq__(self, other):
        return isinstance(other, Left) and self.get == other.get
    
    def __bool__(self):
        return False
    
    def __repr__(self):
        return f'Left({self.get})'
    
    def and_then(self, f):
        """
        Chain together functions of either computations, keeping
        track of whether or not any of them have failed
        :example:

        >>> f = lambda i: Right(1 / i) if i != 0 else Left('i was 0')
        >>> Right(1).and_then(f)
        Right(1.0)
        >>> Right(0).and_then(f)
        Left('i was 0')

        :type f: Callable[[A], Either[B, C]]
        :param f: The function to call
        :return: :class:`Right` of type A if \
        the computation was successful, :class:`Left` of type B otherwise.
        :rtype: Either[B, C]
        """
        return self._and_then(f)
    
    cdef _Either _and_then(self, object f):
        return self
    
    def or_else(self, default):
        """
        Try to get the result of this either computation, return default
        if this is a ``Left`` value

        :example:
        >>> Right(1).or_else(2)
        1
        >>> Left(1).or_else(2)
        2
        
        :type default: A
        :param default: Value to return if this is a ``Left`` value
        :return: Result of computation if this is a ``Right`` value, \
                 default otherwise
        """
        return default

def tail_rec(f, init):
    """
    Run a stack safe recursive monadic function `f`
    by calling `f` with :class:`Left` values
    until a :class:`Right` value is produced
    
    :example:
    >>> def f(i: str) -> Either[Either[int, str]]:
    ...     if i == 0:
    ...         return Right(Right('Done'))
    ...     return Right(Left(i - 1))
    >>> tail_rec(f, 5000)
    Right('Done')

    :type f: Callable[[B], Either[A, Either[B, C]]]
    :param f: function to run "recursively"
    :param a: initial argument to `f`
    :return: result of `f`
    :rtype: Either[D, C]
    """
    return _tail_rec(f, init)


cdef _Either _tail_rec(object f, object init):
    cdef _Either outer_either
    cdef _Either inner_either
    outer_either = f(init)
    if isinstance(outer_either, Left):
        return outer_either
    inner_either = outer_either.get
    while isinstance(inner_either, Left):
        outer_either = f(inner_either.get)
        if isinstance(outer_either, Left):
            return outer_either
        inner_either = outer_either.get
    return inner_either

def either(f):
    """
    Turn ``f`` into a monadic function in the ``Either`` monad by wrapping
    in it a :class:`Right`
    
    :example:
    >>> either(lambda v: v)(1)
    Right(1)

    :type f: Callable[..., C]
    :param f: function to wrap
    :return: ``f`` wrapped with a ``Right``
    :rtype: Callable[..., Either[B, C]]
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        return Right(f(*args, **kwargs))
    return decorator

def flatten(eithers):
    """
    Extract value from each :class:`Either`, ignoring
    elements that are :class:`Left`

    :type eithers: Iterable[Either[B, A]]
    :param eithers: Sequence of :class:`Either`
    :return: :class:`List` of unwrapped values
    :rtype: List[A]
    """
    return _flatten(eithers)

cdef List _flatten(object maybes):
    return _list(m.get for m in maybes if isinstance(m, Right))

def sequence(eithers):
    """
    Evaluate each ``Either`` in `iterable` from left to right
    and collect the results
    
    :example:
    >>> sequence([Right(v) for v in range(3)])
    Right((0, 1, 2))

    :type eithers: Iterable[Either[B, A]]
    :param eithers: The iterable to collect results from
    :returns: ``Either`` of collected results
    :rtype: Either[B, Tuple[A]]
    """
    return _sequence(eithers)

cdef _Either _wrap(object value):
    return Right(value)

cdef _Either _sequence(object eithers):
    return _sequence_(<wrap_t>_wrap, eithers)

def map_m(f, iterable):
    """
    Map each in element in ``iterable`` to
    an :class:`Either` by applying ``f``,
    combine the elements by ``and_then``
    from left to right and collect the results

    :example:
    >>> map_m(Right, range(3))
    Right((0, 1, 2))

    :type f: Callable[[A], Either[B, C]]
    :param f: Function to map over ``iterable``
    :type iterable: Iterable[A]
    :param iterable: Iterable to map ``f`` over
    :return: ``f`` mapped over ``iterable`` and combined from left to right.
    :rtype: Either[B, Tuple[C]]
    """
    return _map_m(f, iterable)

cdef _Either _map_m(object f, object xs):
    return _map_m_(<wrap_t>_wrap, f, xs)

def filter_m(f, iterable):
    """
    Map each element in ``iterable`` by applying ``f``,
    filter the results by the value returned by ``f``
    and combine from left to right.
    
    :example:
    >>> filter_m(lambda v: Right(v % 2 == 0), range(3))
    Right((0, 2))

    :type f: Callable[[A], Either[B, C]]
    :param f: Function to map ``iterable`` by
    :type iterable: Iterable[A]
    :param iterable: Iterable to map by ``f``
    :return: `iterable` mapped and filtered by `f`
    :rtype: Either[B, Tuple[C]]
    """
    return _filter_m_(<wrap_t>_wrap, f, iterable)

# hack to make it possible to
# import the type alias from .pyi
Either = Union
Eithers = Generator

def with_effect(f):
    """
    Decorator for functions that
    return a generator of eithers and a final result.
    Iteraters over the yielded eithers and sends back the
    unwrapped values using "and_then"
    
    :example:
    >>> @with_effect
    ... def f() -> Eithers[int, int]:
    ...     a = yield Right(2)
    ...     b = yield Right(2)
    ...     return a + b
    >>> f()
    Right(4)

    :type f: Callable[..., Eithers[A, B, C]]
    :param f: generator function to decorate
    :return: `f` decorated such that generated :class:`Either` \
        will be chained together with `and_then`
    :rtype: Callable[..., Either[A, C]]
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect_tail_rec(<wrap_t>_wrap, g, <tail_rec_t>_tail_rec)
    return decorator
