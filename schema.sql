-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── ROUTES ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS routes (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    short_name  VARCHAR(20)  NOT NULL,
    direction   SMALLINT     NOT NULL CHECK (direction IN (0, 1)),
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── STATIONS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stations (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    name_ar     VARCHAR(150),
    lat         DOUBLE PRECISION NOT NULL,
    lng         DOUBLE PRECISION NOT NULL,
    sequence    SMALLINT     NOT NULL,
    route_id    INT          NOT NULL REFERENCES routes(id),
    is_terminal BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_stations_route ON stations(route_id, sequence);

-- ── SCHEDULE ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS schedule (
    id          SERIAL PRIMARY KEY,
    station_id  INT      NOT NULL REFERENCES stations(id),
    route_id    INT      NOT NULL REFERENCES routes(id),
    direction   SMALLINT NOT NULL,
    arrival_min INT      NOT NULL,
    day_mask    SMALLINT NOT NULL DEFAULT 127,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_schedule_lookup ON schedule(station_id, direction, arrival_min);

-- ── GPS PINGS (anonymous) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS gps_pings (
    id           BIGSERIAL    PRIMARY KEY,
    session_hash VARCHAR(64)  NOT NULL,
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    speed_kmh    REAL,
    bearing      SMALLINT,
    accuracy_m   REAL,
    route_id     INT REFERENCES routes(id),
    ts           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gps_recent ON gps_pings(route_id, ts DESC);

-- ── ETA LOG (for accuracy tracking) ─────────────────────────
CREATE TABLE IF NOT EXISTS eta_log (
    id            BIGSERIAL   PRIMARY KEY,
    station_id    INT         NOT NULL REFERENCES stations(id),
    direction     SMALLINT    NOT NULL,
    predicted_eta TIMESTAMPTZ NOT NULL,
    actual_eta    TIMESTAMPTZ,
    source        VARCHAR(20) NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
