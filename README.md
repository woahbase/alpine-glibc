[![build status][251]][232] [![commit][255]][231] [![version:x86_64][256]][235] [![size:x86_64][257]][235] [![version:armhf][258]][236] [![size:armhf][259]][236] [![version:armv7l][260]][237] [![size:armv7l][261]][237] [![version:aarch64][262]][238] [![size:aarch64][263]][238]

## [Alpine-GLibC][234]
#### Container for Alpine Linux + S6 + GNU LibC
---

This [image][233] serves as the base image for
applications/services that need the GNU C Library to run the
binary linked against it.

Based on [Alpine Linux][131] from my [alpine-s6][132] image with
the [s6][133] init system [overlayed][134] in it.

The image is tagged respectively for the following architectures,
* **armhf**   - GLibC from [SatoshiPortal][136]
* **armv7l**  - GLibC from [SatoshiPortal][136]
* **aarch64** - GLibC from [SatoshiPortal][136]
* **x86_64**  - GLibC from [sgerrand][135] ( retagged as the `latest` )

**non-x86_64** builds have embedded binfmt_misc support and contain the
[qemu-user-static][105] binary that allows for running it also inside
an x86_64 environment that has it.

---
#### Get the Image
---

Pull the image for your architecture it's already available from
Docker Hub.

```
# make pull
docker pull woahbase/alpine-glibc:x86_64
```

---
#### Run
---

If you want to run images for other architectures, you will need
to have binfmt support configured for your machine. [**multiarch**][104],
has made it easy for us containing that into a docker container.

```
# make regbinfmt
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Without the above, you can still run the image that is made for your
architecture, e.g for an x86_64 machine..

Running `make` gets a shell.

```
# make
# or
# make shell
docker run --rm -it \
  --name docker_glibc --hostname glibc \
  woahbase/alpine-glibc:x86_64 \
  /bin/bash
```

Stop the container with a timeout, (defaults to 2 seconds)

```
# make stop
docker stop -t 2 docker_glibc
```

Removes the container, (always better to stop it first and `-f`
only when needed most)

```
# make rm
docker rm -f docker_glibc
```

Restart the container with

```
# make restart
docker restart docker_glibc
```

---
#### Shell access
---

Get a shell inside a already running container,

```
# make debug
docker exec -it docker_glibc /bin/bash
```

set user or login as root,

```
# make rdebug
docker exec -u root -it docker_glibc /bin/bash
```

To check logs of a running container in real time

```
# make logs
docker logs -f docker_glibc
```

---
### Development
---

If you have the repository access, you can clone and
build the image yourself for your own system, and can push after.

---
#### Setup
---

Before you clone the [repo][231], you must have [Git][101], [GNU make][102],
and [Docker][103] setup on the machine.

```
git clone https://github.com/woahbase/alpine-glibc
cd alpine-glibc
```
You can always skip installing **make** but you will have to
type the whole docker commands then instead of using the sweet
make targets.

---
#### Build
---

You need to have binfmt_misc configured in your system to be able
to build images for other architectures.

Otherwise to locally build the image for your system.
[`ARCH` defaults to `x86_64`, need to be explicit when building
for other architectures.]

```
# make ARCH=x86_64 build
# sets up binfmt if not x86_64
docker build --rm --compress --force-rm \
  --no-cache=true --pull \
  -f ./Dockerfile_x86_64 \
  --build-arg DOCKERSRC=woahbase/alpine-s6:x86_64 \
  -t woahbase/alpine-glibc:x86_64 \
  .
```

To check if its working..

```
# make ARCH=x86_64 test
docker run --rm -it \
  --name docker_glibc --hostname glibc \
  --entrypoint /init \
  woahbase/alpine-glibc:x86_64 \
  sh -ec 'bash --version'
```

And finally, if you have push access,

```
# make ARCH=x86_64 push
docker push woahbase/alpine-glibc:x86_64
```

---
### Maintenance
---

Sources at [Github][106]. Built at [Travis-CI.org][107] (armhf / x64 builds). Images at [Docker hub][108]. Metadata at [Microbadger][109].

Maintained by [WOAHBase][204].

[101]: https://git-scm.com
[102]: https://www.gnu.org/software/make/
[103]: https://www.docker.com
[104]: https://hub.docker.com/r/multiarch/qemu-user-static/
[105]: https://github.com/multiarch/qemu-user-static/releases/
[106]: https://github.com/
[107]: https://travis-ci.org/
[108]: https://hub.docker.com/
[109]: https://microbadger.com/

[131]: https://alpinelinux.org/
[132]: https://hub.docker.com/r/woahbase/alpine-s6
[133]: https://skarnet.org/software/s6/
[134]: https://github.com/just-containers/s6-overlay
[135]: https://github.com/sgerrand/alpine-pkg-glibc
[136]: https://github.com/SatoshiPortal/alpine-pkg-glibc/releases

[201]: https://github.com/woahbase
[202]: https://travis-ci.org/woahbase/
[203]: https://hub.docker.com/u/woahbase
[204]: https://woahbase.online/

[231]: https://github.com/woahbase/alpine-glibc
[232]: https://travis-ci.org/woahbase/alpine-glibc
[233]: https://hub.docker.com/r/woahbase/alpine-glibc
[234]: https://woahbase.online/#/images/alpine-glibc
[235]: https://microbadger.com/images/woahbase/alpine-glibc:x86_64
[236]: https://microbadger.com/images/woahbase/alpine-glibc:armhf
[237]: https://microbadger.com/images/woahbase/alpine-glibc:armv7l
[238]: https://microbadger.com/images/woahbase/alpine-glibc:aarch64

[251]: https://travis-ci.org/woahbase/alpine-glibc.svg?branch=master

[255]: https://images.microbadger.com/badges/commit/woahbase/alpine-glibc.svg

[256]: https://images.microbadger.com/badges/version/woahbase/alpine-glibc:x86_64.svg
[257]: https://images.microbadger.com/badges/image/woahbase/alpine-glibc:x86_64.svg

[258]: https://images.microbadger.com/badges/version/woahbase/alpine-glibc:armhf.svg
[259]: https://images.microbadger.com/badges/image/woahbase/alpine-glibc:armhf.svg

[260]: https://images.microbadger.com/badges/version/woahbase/alpine-glibc:armv7l.svg
[261]: https://images.microbadger.com/badges/image/woahbase/alpine-glibc:armv7l.svg

[262]: https://images.microbadger.com/badges/version/woahbase/alpine-glibc:aarch64.svg
[263]: https://images.microbadger.com/badges/image/woahbase/alpine-glibc:aarch64.svg
