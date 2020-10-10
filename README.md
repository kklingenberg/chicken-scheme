# chicken-scheme dockerfiles

Dockerfiles useful for [chicken scheme](https://www.call-cc.org/)
development. An optional custom `chicken-assemble` script is also
provided, used to build projects in an opinionated, structured way.

You may pick a flavour built on top of popular linux distros:

```bash
docker pull plotter/chicken-scheme:5.2.0-alpine
docker pull plotter/chicken-scheme:5.2.0-debian
docker pull plotter/chicken-scheme:5.2.0-ubuntu
docker pull plotter/chicken-scheme:5.2.0-centos
```

## How to use these images

Mount your source code directory into a running container to access
chicken's REPL and/or compiler:

```bash
docker run --rm -it --workdir /src -v $(pwd):/src plotter/chicken-scheme
```

For truly static builds, prefer the `alpine` base image and set the
proper compiler and linker flags:

```dockerfile
FROM plotter/chicken-scheme:5.2.0-alpine
WORKDIR /src
COPY . .
RUN csc -static -L -static -L -no-pie main.scm
ENTRYPOINT ["/src/main"]
```

You may also choose to build a barebones `scratch` image containing
only the desired binary:

```dockerfile
FROM plotter/chicken-scheme:5.2.0-alpine as build
WORKDIR /src
COPY . .
RUN csc -static -L -static -L -no-pie main.scm

FROM scratch
COPY --from=build /src/main /bin/main
ENTRYPOINT ["/bin/main"]
```

## `chicken-assemble`-based projects

`chicken-assemble` is a simple script which builds a single source
file given a directory of source files, to be used for later
compilation. The script wraps each file's contents into a module, and
provides an unofficial `local` import used for referencing in-folder
files as modules.

The following illustrates the appropriate directory structure, in case
you decide to use `chicken-assemble`:

```
.
└── src
    ├── bar
    │   └── baz.scm
    ├── core.scm
    └── foo.scm
```

Where `.` is where you'd put non-source files like a Dockerfile, or
license information.

`src` and `core.scm` are the default values for both arguments of
`chicken-assemble`. They represent the source code folder and the main
module, respectively. `core.scm` should declare a `-main`. The
following is a possible listing of all these files contents
(`core.scm`, `foo.scm` and `bar.scm`):

```scheme
;; file: src/core.scm
(import scheme
        chicken.base
        (local foo))

(define (-main)
  (print (foo/do-thing)))

;; file: src/foo.scm
(import scheme
        chicken.base
        (local bar.baz))

(define (do-thing)
  (print "Doing a thing")
  bar.baz/thing)

;; file: src/bar/baz.scm
(import scheme)

(define thing "The nicest thing")

```

To assemble them all, run:

```bash
chicken-assemble src core > _app.scm
```

And the contents of `_app.scm` would turn out to be:

```scheme
(module bar.baz * (import scheme) (define thing "The nicest thing"))
(module foo * (import scheme chicken.base (prefix bar.baz bar.baz/)) (define (do-thing) (print "Doing a thing") bar.baz/thing))
(module core * (import scheme chicken.base (prefix foo foo/)) (define (-main) (print (foo/do-thing))))
(import (chicken process-context) (prefix core core/))
(apply core/-main (command-line-arguments))
```
