
CREATE TABLE "journal" (
  "id" TEXT NOT NULL,
  "created_at" INTEGER NOT NULL,
  "updated_at" INTEGER NOT NULL,
  "date_from" INTEGER NOT NULL,
  "date_to" INTEGER NOT NULL,
  "type" TEXT NOT NULL,
  "subtype" TEXT,
  "serialized" TEXT NOT NULL,
  "schema_version" INTEGER NOT NULL DEFAULT 0,
  "plain_text" TEXT,
  "latitude" REAL,
  "longitude" REAL,
  "geohash_string" TEXT,
  "geohash_int" INTEGER,
  PRIMARY KEY ("id")
);

CREATE INDEX idx_journal_created_at
ON journal (created_at);

CREATE INDEX idx_journal_updated_at
ON journal (updated_at);

CREATE INDEX idx_journal_date_from
ON journal (date_from);

CREATE INDEX idx_journal_date_to
ON journal (date_to);

CREATE INDEX idx_journal_type
ON journal (type);

CREATE INDEX idx_journal_subtype
ON journal (subtype);

CREATE INDEX idx_journal_geohash_string
ON journal (geohash_string);

CREATE INDEX idx_journal_geohash_int
ON journal (geohash_int);