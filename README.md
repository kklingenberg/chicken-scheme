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
RUN csc ... TODO write proper compilation instruction
ENTRYPOINT ["/src/main"]
```

You may also choose to build a barebones `scratch` image containing
only the desired binary:

```dockerfile
FROM plotter/chicken-scheme:5.2.0-alpine as build
WORKDIR /src
COPY . .
RUN csc ... TODO write proper compilation instruction

FROM scratch
COPY --from=build /src/app /bin/app
ENTRYPOINT ["/bin/app"]
```

## `chicken-assemble`-based projects

TODO explain chicken-assemble and the enforced project structure
