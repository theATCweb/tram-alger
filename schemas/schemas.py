"""
Pydantic request/response schemas for API validation.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator


class StationResponse(BaseModel):
    """Station response schema."""
    id: int
    name: str
    name_ar: Optional[str] = None
    lat: float
    lng: float
    sequence: int
    route_id: int
    is_terminal: bool

    class Config:
        from_attributes = True


class RouteResponse(BaseModel):
    """Route response schema with station count."""
    id: int
    name: str
    short_name: str
    direction: int
    is_active: bool
    station_count: int = 0

    class Config:
        from_attributes = True


class ETAResponse(BaseModel):
    """ETA prediction response schema."""
    station_id: int
    direction: int
    eta_iso: Optional[str] = None
    seconds_away: Optional[int] = None
    source: str
    confidence: float
    message: Optional[str] = None


class GPSPingRequest(BaseModel):
    """GPS ping submission request schema."""
    device_token: str
    lat: float = Field(..., ge=36.65, le=36.90)
    lng: float = Field(..., ge=2.90, le=3.30)
    accuracy_m: float = Field(..., ge=0, le=150)
    speed_kmh: float = Field(..., ge=0, le=120)
    bearing: Optional[int] = Field(None, ge=0, le=360)
    route_id: int
    direction: int = Field(..., ge=0, le=1)

    @field_validator("accuracy_m")
    @classmethod
    def validate_accuracy(cls, v):
        if v > 150:
            raise ValueError("accuracy_m must be <= 150 for low-quality GPS rejection")
        return v


class GPSPingResponse(BaseModel):
    """GPS ping acknowledgment response."""
    accepted: bool
    message: str


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    timestamp: str


class StatsResponse(BaseModel):
    """Admin statistics response."""
    total_stations: int
    active_routes: int
    gps_pings_last_hour: int
    redis_connected: bool
    db_connected: bool
