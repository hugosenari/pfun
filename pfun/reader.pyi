from typing import Generic, TypeVar, Callable, Iterable, Generator, Tuple

from .immutable import Immutable
from .curry import curry

C = TypeVar('C')

A = TypeVar('A')
B = TypeVar('B')


class Reader(Immutable, Generic[C, A]):
    def and_then(self, f: 'Callable[[A], Reader[C, B]]') -> 'Reader[C, B]':
        ...

    def map(self, f: Callable[[A], B]) -> 'Reader[C, B]':
        ...

    def run(self, c: C) -> A:
        ...


def wrap(value: A) -> Reader[C, A]:
    ...


def ask() -> Reader[C, C]:
    ...


def reader(f: Callable[..., B]) -> Callable[..., Reader[C, B]]:
    ...


@curry
def map_m(f: Callable[[A], Reader[C, B]],
          iterable: Iterable[A]) -> Reader[C, Tuple[B]]:
    ...


def sequence(iterable: Iterable[Reader[C, B]]) -> Reader[C, Tuple[B]]:
    ...


@curry
def filter_m(f: Callable[[A], Reader[C, bool]],
             iterable: Iterable[A]) -> Reader[C, Tuple[A]]:
    ...


Readers = Generator[Reader[C, A], A, B]


def with_effect(f: Callable[..., Readers[C, A, B]]
                ) -> Callable[..., Reader[C, B]]:
    ...
