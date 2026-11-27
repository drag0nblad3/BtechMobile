# Official unit catalog shards

The migrated catalogs contain eight Mech arrays (tech base and weight class),
four vehicle arrays (motive type), and two battle armor arrays (tech base).
Every original authored dictionary is preserved, including Omni configurations,
equipment order and original ID. Missing tech base is classified as Inner Sphere.

UnitCatalog.records sorts official records by ID before expansion, matching the
original filename order. Fixture directories retain their original order.
UnitCatalog.record retrieves an individual logical design by its old path.
New or revised official designs belong in the appropriate array, sorted by ID.

tools/migrate_unit_catalogs.py is the one-time migration utility for a legacy
checkout. It stages and verifies exact compacted source bytes, classification,
record coverage and order before --apply replaces original files. Do not run
--apply against an already migrated catalog. Assets and fixtures are unchanged.
