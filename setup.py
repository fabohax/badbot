from sys import version_info

from setuptools import setup


if version_info.major == 3 and version_info.minor < 6 or \
        version_info.major < 3:
    print('Your Python interpreter must be 3.6 or greater!')
    exit(1)

from pathlib import Path  # noqa: E402

from bitbot import __version__  # noqa: E402


readme_file = Path(__file__).parent / "README.md"
readme_long = "Crypto Trader Bot"
if readme_file.is_file():
    readme_long = (Path(__file__).parent / "README.md").read_text()

# Requirements used for submodules
api = ['flask', 'flask-jwt-extended', 'flask-cors']
plot = ['plotly>=4.0']

develop = [
    'coveralls',
    'flake8',
    'flake8-type-annotations',
    'flake8-tidy-imports',
    'mypy',
    'pytest',
    'pytest-asyncio',
    'pytest-cov',
    'pytest-mock',
    'pytest-random-order',
]

jupyter = [
    'jupyter',
    'nbstripout',
    'ipykernel',
    'nbconvert',
    ]

all_extra = api + plot + develop + jupyter

setup(name='bitbot',
      version=__version__,
      description='Crypto Trader Bot',
      long_description=readme_long,
      long_description_content_type="text/markdown",
      url='https://github.com/fabohax/bitbot',
      author='inomoxo',
      author_email='40230@pm.me',
      license='GPLv3',
      packages=['bitbot'],
      setup_requires=['pytest-runner', 'numpy'],
      tests_require=['pytest', 'pytest-asyncio', 'pytest-cov', 'pytest-mock', ],
      install_requires=[
          # from requirements.txt
          'ccxt>=1.24.96',
          'SQLAlchemy',
          'python-telegram-bot',
          'arrow>=0.17.0',
          'cachetools',
          'requests',
          'urllib3',
          'wrapt',
          'jsonschema',
          'TA-Lib',
          'tabulate',
          'pycoingecko',
          'py_find_1st',
          'python-rapidjson',
          'sdnotify',
          'colorama',
          'jinja2',
          'questionary',
          'prompt-toolkit',
          'numpy',
          'pandas',
          'tables',
          'blosc',
      ],
      extras_require={
          'api': api,
          'dev': all_extra,
          'plot': plot,
          'jupyter': jupyter,
          'all': all_extra,
      },
      include_package_data=True,
      zip_safe=False,
      entry_points={
          'console_scripts': [
              'bitbot = bitbot.main:main',
          ],
      },
      classifiers=[
          'Environment :: Console',
          'Intended Audience :: Science/Research',
          'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
          'Programming Language :: Python :: 3.6',
          'Programming Language :: Python :: 3.7',
          'Programming Language :: Python :: 3.8',
          'Operating System :: Unix',
          'Topic :: Office/Business :: Financial :: Investment',
      ])
