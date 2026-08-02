# Marketplace-Scale Generated Fixture

This fixture profile represents a catalog with 10,000,000 Offerings and 100,000 Collections without
committing or materializing the complete catalog. The generator constructs deterministic first,
middle, and final pages directly from their offsets. Work and memory for a catalog page therefore
depend on the requested page size, not the total catalog size.

The profile also exercises the maximum effective filter and sort catalogs, the maximum refinement
shape, Service Document size, and ODP page byte limits. Checks use structural budgets rather than a
wall-clock conformance threshold. Elapsed time is diagnostic because shared continuous-integration
runners do not provide stable timing.

Run the check:

```sh
make -C ietf check-marketplace-scale
```

Write the representative generated documents to a disposable directory:

```sh
make -C ietf generate-marketplace-scale OUTPUT=/tmp/odp-marketplace-scale
```

The output contains the profile, Service Document, sampled Collection and Offering pages, every
bounded capability page, and a maximum-shape refinement response. Generated output is reproducible
and is not source material.
