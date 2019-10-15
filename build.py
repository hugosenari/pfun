from Cython.Build import cythonize


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
                    'pfun/state.pyx'
                ],
                language_level='1'
            )
        }
    )
