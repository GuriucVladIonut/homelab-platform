# ADR-0007 — Filesystem Media, PostgreSQL Metadata

## Status

Accepted for implementation.

## Decision

Binary media remains on the host filesystem under `/srv/homelab/data/`. PostgreSQL stores catalog metadata, migrations, audit records, and application state; it never stores media blobs.

Ingestion is validate → metadata → checksum → duplicate check → atomic move → catalog transaction → audit. The catalog validates paths against an allowlisted root and distinguishes metadata deletion from physical-file deletion.

## Consequences

Filesystem and database consistency must be handled explicitly. PostgreSQL backups and filesystem backups are separate concerns. Physical deletion requires explicit confirmation and preferably soft-delete/trash semantics.
