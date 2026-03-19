"""
SQLAlchemy ORM models for the Tram Alger database.
"""
from datetime import datetime
from sqlalchemy import (
    Column, Integer, BigInteger, String, Boolean, SmallInteger,
    Float, DateTime, ForeignKey, Index
)
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.sql import func


class Base(DeclarativeBase):
    pass


class Route(Base):
    """Tram route model."""
    __tablename__ = "routes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    short_name = Column(String(20), nullable=False)
    direction = Column(SmallInteger, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=func.now())


class Station(Base):
    """Station model along a route."""
    __tablename__ = "stations"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(150), nullable=False)
    name_ar = Column(String(150), nullable=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    sequence = Column(SmallInteger, nullable=False)
    route_id = Column(Integer, ForeignKey("routes.id"), nullable=False)
    is_terminal = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=func.now())

    __table_args__ = (
        Index("idx_stations_route", "route_id", "sequence"),
    )


class Schedule(Base):
    """Schedule for arrivals at each station."""
    __tablename__ = "schedule"

    id = Column(Integer, primary_key=True, autoincrement=True)
    station_id = Column(Integer, ForeignKey("stations.id"), nullable=False)
    route_id = Column(Integer, ForeignKey("routes.id"), nullable=False)
    direction = Column(SmallInteger, nullable=False)
    arrival_min = Column(Integer, nullable=False)
    day_mask = Column(SmallInteger, nullable=False, default=127)
    created_at = Column(DateTime(timezone=True), nullable=False, default=func.now())

    __table_args__ = (
        Index("idx_schedule_lookup", "station_id", "direction", "arrival_min"),
    )


class GPSPing(Base):
    """Anonymous GPS ping from a tram passenger."""
    __tablename__ = "gps_pings"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    session_hash = Column(String(64), nullable=False)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    speed_kmh = Column(Float, nullable=True)
    bearing = Column(SmallInteger, nullable=True)
    accuracy_m = Column(Float, nullable=True)
    route_id = Column(Integer, ForeignKey("routes.id"), nullable=True)
    ts = Column(DateTime(timezone=True), nullable=False, default=func.now())

    __table_args__ = (
        Index("idx_gps_recent", "route_id", "ts"),
    )


class ETALog(Base):
    """ETA prediction log for accuracy tracking."""
    __tablename__ = "eta_log"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    station_id = Column(Integer, ForeignKey("stations.id"), nullable=False)
    direction = Column(SmallInteger, nullable=False)
    predicted_eta = Column(DateTime(timezone=True), nullable=False)
    actual_eta = Column(DateTime(timezone=True), nullable=True)
    source = Column(String(20), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=func.now())
