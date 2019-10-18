from Cython.Build import cythonize
from Cython.Compiler import Options

# required to be able to mock 'print' and 'open'
# in 'io' tests
Options.cache_builtins = False


def build(setup_kwargs):
    setup_kwargs.update(
        {
            'ext_modules':
            cythonize(
                [
                    'pfun/trampoline.pyx',
                    'pfun/list.pyx',
                    'pfun/reader.pyx',
                    'pfun/monad.pyx',
                    'pfun/maybe.pyx',
                    'pfun/either.pyx',
                    'pfun/io.pyx',
                    'pfun/state.pyx',
                    'pfun/writer.pyx',
                    'pfun/cont.pyx'
                ],
                compiler_directives={
                    # required to generate docs
                    'embedsignature': True,
                    # required for e.g 'print' to have correct signature
                    'language_level': 3,
                    # required for 'curry' to work
                    # on cythonized functions because it relies on
                    # 'inspect.signature'
                    'binding': True
                }
            )
        }
    )
