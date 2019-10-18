from hypothesis import given, assume

from pfun import writer
from pfun import identity, compose
from tests.monad_test import MonadTest
from tests.strategies import anything, unaries, writers, monoids
from .utils import recursion_limit


class TestWriter(MonadTest):
    @given(anything())
    def test_right_identity_law(self, value):
        assert (writer.wrap(value).and_then(writer.wrap) == writer.wrap(value))

    @given(unaries(writers()), anything())
    def test_left_identity_law(self, f, value):
        assert writer.wrap(value).and_then(f) == f(value)

    @given(writers(), unaries(writers()), unaries(writers()))
    def test_associativity_law(self, w, f, g):
        assert w.and_then(f).and_then(g) == w.and_then(
            lambda x: f(x).and_then(g)
        )

    @given(anything())
    def test_equality(self, value):
        assert writer.wrap(value) == writer.wrap(value)
        assert writer.wrap(value) != value

    @given(anything(), anything())
    def test_inequality(self, first, second):
        assume(first != second)
        assert writer.wrap(first) != writer.wrap(second)

    @given(anything())
    def test_identity_law(self, value):
        assert writer.wrap(value).map(identity) == writer.wrap(value)

    @given(unaries(), unaries(), anything())
    def test_composition_law(self, f, g, value):
        h = compose(f, g)
        assert writer.wrap(value).map(h) == writer.wrap(value).map(g).map(f)

    @given(monoids())
    def test_tell(self, monoid):
        assert writer.tell(monoid) == writer.Writer(None, monoid)

    def test_with_effect(self):
        @writer.with_effect
        def f():
            a = yield writer.wrap(2)
            b = yield writer.wrap(2)
            return a + b

        assert f() == writer.wrap(4)

        @writer.with_effect
        def test_stack_safety():
            for _ in range(500):
                yield writer.wrap(1)
            return None

        with recursion_limit(100):
            test_stack_safety()

    def test_sequence(self):
        assert writer.sequence([writer.wrap(v)
                                for v in range(3)]) == writer.wrap((0, 1, 2))

    def test_stack_safety(self):
        with recursion_limit(100):
            writer.sequence([writer.wrap(v) for v in range(500)])

    def test_filter_m(self):
        assert writer.filter_m(lambda v: writer.wrap(v % 2 == 0),
                               range(3)) == writer.wrap((0, 2))

    def test_map_m(self):
        assert writer.map_m(writer.wrap, range(3)) == writer.wrap((0, 1, 2))
