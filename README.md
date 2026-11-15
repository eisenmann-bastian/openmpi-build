# Open MPI binary builder

Builds Open MPI 4.1.8 from the official, checksum-verified source on Linux.
The output is a standalone compressed binary installation, not a Docker image
or a system package. It does not require Docker.

```sh
./build.sh
```

The native Linux build requires `curl`, `sha256sum`, `tar`, `make`, a C/C++
compiler and standard C development headers (for Ubuntu, `build-essential`,
`curl` and `ca-certificates`). The host architecture must be ARM64 or AMD64.
Cross-compilation and macOS are not supported. Use a host compatible with the
target runtime; Linux binaries built on newer distributions can depend on
newer system libraries and may not run on older ones.

The archive is written to
`../binaries/openmpi/<architecture>/openmpi-4.1.8-linux-<architecture>.tar.gz`.
Set `OPENMPI_OUTPUT_DIR` to use another directory. The script refuses to
overwrite an existing archive. It is configured for installation at
`/opt/openmpi/4.1.8`; extract it there to use it without relocating it.

Open MPI retains its own license, included in the archive at
`share/doc/openmpi/LICENSE`.

Run the lightweight script tests with `python3 -m unittest discover -s tests -v`.

The builder files are available under the [BSD 3-Clause License](LICENSE).
