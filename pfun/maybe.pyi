from typing import (
    Generic,
    TypeVar,
    Callable,
    Any,
    Sequence,
    Iterable,
    Generator,
    Union
)

from .immutable import Immutable
from .list import List
from .curry import curry
from .either import Either

A = TypeVar('A')
B = TypeVar('B')


class Just(Immutable, Generic[A]):
    get: A

    def and_then(self, f: Callable[[A], 'Maybe[B]']) -> 'Maybe[B]':
        ...

    def map(self, f: Callable[[A], B]) -> 'Maybe[B]':
        ...

    def or_else(self, default: A) -> A:
        ...

    def __eq__(self, other: Any) -> bool:
        ...

    def __repr__(self):
        return f'Just({repr(self.get)})'

    def __bool__(self):
        return True


class Nothing(Immutable):
    def and_then(self, f: Callable[[A], 'Maybe[B]']) -> 'Maybe[B]':
        ...

    def __eq__(self, other: Any) -> bool:
        ...

    def __repr__(self):
        ...

    def or_else(self, default: A) -> A:
        ...

    def map(self, f: Callable[[Any], B]) -> 'Maybe[B]':
        ...

    def __bool__(self) -> bool:
        ...


Maybe = Union[Nothing, Just[A]]


def maybe(f: Callable[..., B]) -> Callable[..., Maybe[B]]:
    ...


def flatten(maybes: Sequence[Maybe[A]]) -> List[A]:
    ...


@curry
def map_m(f: Callable[[A], Maybe[B]],
          iterable: Iterable[A]) -> Maybe[Iterable[B]]:
    ...


def sequence(iterable: Iterable[Maybe[A]]) -> Maybe[Iterable[A]]:
    ...


@curry
def filter_m(f: Callable[[A], Maybe[bool]],
             iterable: Iterable[A]) -> Maybe[Iterable[A]]:
    ...


S = TypeVar('S')
R = TypeVar('R')
Maybes = Generator[Maybe[S], S, R]


def with_effect(f: Callable[..., Maybes[Any, R]]) -> Callable[..., Maybe[R]]:
    ...


def tail_rec(f: Callable[[A], Maybe[Either[A, B]]], a: A) -> Maybe[B]:
    ...
