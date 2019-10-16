from .monad_test import MonadTest
from .strategies import anything, unaries, readers
from hypothesis import given, assume
from pfun import reader, identity, compose
from pfun.list import list_
from .utils import recursion_limit


class TestReader(MonadTest):
    @given(anything(), anything())
    def test_right_identity_law(self, value, context):
        assert (
            reader.wrap(value).and_then(
                reader.wrap
            ).run(context) == reader.wrap(value).run(context)
        )

    @given(unaries(readers()), anything(), anything())
    def test_left_identity_law(self, f, value, context):
        assert (
            reader.wrap(value).and_then(f).run(context) == f(value
                                                             ).run(context)
        )

    @given(readers(), unaries(readers()), unaries(readers()), anything())
    def test_associativity_law(self, r, f, g, context):
        assert (
            r.and_then(f).and_then(g).run(context) ==
            r.and_then(lambda x: f(x).and_then(g)).run(context)
        )

    @given(anything(), anything())
    def test_equality(self, value, context):
        assert reader.wrap(value).run(context) == reader.wrap(value
                                                              ).run(context)

    @given(anything(), anything(), anything())
    def test_inequality(self, first, second, context):
        assume(first != second)
        assert reader.wrap(first).run(context) != reader.wrap(second
                                                              ).run(context)

    @given(anything(), anything())
    def test_identity_law(self, value, context):
        assert (
            reader.wrap(value).map(identity).run(context) ==
            reader.wrap(value).run(context)
        )

    @given(unaries(), unaries(), anything(), anything())
    def test_composition_law(self, f, g, value, context):
        h = compose(f, g)
        assert (
            reader.wrap(value).map(h).run(context) ==
            reader.wrap(value).map(g).map(f).run(context)
        )

    def test_reader_decorator(self):
        reader_int = reader.reader(int)
        assert reader_int('1').run(None) == 1

    def test_ask(self):
        reader.ask().run('context') == 'context'

    def test_with_effect(self):
        @reader.with_effect
        def f():
            a = yield reader.wrap(2)
            b = yield reader.wrap(2)
            return a + b

        assert f().run(None) == 4

        @reader.with_effect
        def test_stack_safety():
            for _ in range(500):
                yield reader.wrap(1)
            return None

        with recursion_limit(100):
            test_stack_safety().run(None)

    def test_sequence(self):
        assert reader.sequence([reader.wrap(v)
                                for v in range(3)]).run(None) == (0, 1, 2)

    def test_stack_safety(self):
        with recursion_limit(100):
            reader.sequence([reader.wrap(v) for v in range(500)]).run(None)

    def test_filter_m(self):
        assert reader.filter_m(lambda v: reader.wrap(v % 2 == 0),
                               range(3)).run(None) == (0, 2)

    def test_map_m(self):
        assert reader.map_m(reader.wrap, range(3)).run(None) == (0, 1, 2)
