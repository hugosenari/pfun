from __future__ import annotations

from typing import (
    Generic, TypeVar, Callable, Any, Iterable, Union, Generator
)

from .immutable import Immutable
from .curry import curry

A = TypeVar('A')
B = TypeVar('B')
C = TypeVar('C')


class Right(Immutable, Generic[A]):
    get: A

    def or_else(self, default: A) -> A:
        ...

    def map(self, f: Callable[[A], C]) -> Either[B, C]:
        ...

    def and_then(self, f: Callable[[A], Either[B, C]]) -> Either[B, C]:
        ...

    def __eq__(self, other: Any) -> bool:
        ...

    def __bool__(self) -> bool:
        ...

    def __repr__(self) -> str:
        ...


class Left(Immutable, Generic[B]):
    get: B

    def or_else(self, default: A) -> A:
        ...

    def map(self, f: Callable[[A], C]) -> Either[B, C]:
        ...

    def __eq__(self, other: object) -> bool:
        ...

    def __bool__(self) -> bool:
        ...

    def and_then(self, f: Callable[[A], Either[B, C]]) -> Either[B, C]:
        ...

    def __repr__(self) -> str:
        ...


Either = Union[Left[B], Right[A]]


def either(f: Callable[..., A]) -> Callable[..., Either[A, B]]:
    ...


def sequence(iterable: Iterable[Either[A, B]]) -> Either[Iterable[A], B]:
    ...


@curry
def map_m(f: Callable[[A], Either[B, C]],
          iterable: Iterable[A]) -> Either[Iterable[B], C]:
    ...


@curry
def filter_m(f: Callable[[A], Either[bool, B]],
             iterable: Iterable[A]) -> Either[Iterable[A], B]:
    ...


def tail_rec(f: Callable[[A], Either[C, Either[A, B]]], a: A) -> Either[C, B]:
    ...


Eithers = Generator[Either[A, B], B, C]


def with_effect(f: Callable[..., Eithers[A, B, C]]
                ) -> Callable[..., Either[A, C]]:
    ...
