"""
GPS Simulator for Tram Alger Line 1.
Simulates a tram moving from station to station with realistic GPS data.
"""
import asyncio
import random
import math
import argparse
from datetime import datetime
from typing import List, Tuple
import httpx


STATIONS_LINE1 = [
    (36.7356, 3.0490),
    (36.7381, 3.0528),
    (36.7401, 3.0569),
    (36.7424, 3.0611),
    (36.7449, 3.0652),
    (36.7475, 3.0695),
    (36.7501, 3.0738),
    (36.7529, 3.0782),
    (36.7558, 3.0826),
    (36.7587, 3.0869),
    (36.7613, 3.0911),
    (36.7638, 3.0953),
    (36.7664, 3.0996),
    (36.7689, 3.1038),
    (36.7715, 3.1080),
    (36.7741, 3.1122),
    (36.7766, 3.1165),
    (36.7792, 3.1207),
    (36.7818, 3.1250),
    (36.7843, 3.1292),
    (36.7869, 3.1334),
    (36.7894, 3.1377),
    (36.7920, 3.1419),
    (36.7945, 3.1461),
    (36.7971, 3.1504),
    (36.7996, 3.1546),
    (36.8022, 3.1588),
    (36.8047, 3.1631),
    (36.8073, 3.1673),
    (36.8098, 3.1715),
    (36.8124, 3.1758),
    (36.8149, 3.1800),
]

PACKET_LOSS_RATE = 0.08
NOISE_AMPLITUDE = 0.00005


def interpolate_position(from_lat: float, from_lng: float, to_lat: float, to_lng: float, t: float) -> Tuple[float, float]:
    """Linear interpolation between two points."""
    return (
        from_lat + (to_lat - from_lat) * t,
        from_lng + (to_lng - from_lng) * t
    )


def add_noise(lat: float, lng: float) -> Tuple[float, float]:
    """Add GPS noise."""
    return (
        lat + random.uniform(-NOISE_AMPLITUDE, NOISE_AMPLITUDE),
        lng + random.uniform(-NOISE_AMPLITUDE, NOISE_AMPLITUDE)
    )


def get_nearest_sequence(lat: float, lng: float) -> int:
    """Return the sequence number of the nearest station."""
    min_dist = float('inf')
    nearest_seq = 1
    for idx, (s_lat, s_lng) in enumerate(STATIONS_LINE1):
        dist = math.sqrt((lat - s_lat)**2 + (lng - s_lng)**2)
        if dist < min_dist:
            min_dist = dist
            nearest_seq = idx + 1
    return nearest_seq


async def send_gps_ping(
    client: httpx.AsyncClient,
    lat: float,
    lng: float,
    route_id: int,
    direction: int,
    speed: float,
    device_token: str
) -> bool:
    """Send a GPS ping to the API."""
    if random.random() < PACKET_LOSS_RATE:
        return False

    try:
        response = await client.post(
            f"http://localhost:8000/gps/ping",
            json={
                "device_token": device_token,
                "lat": round(lat, 6),
                "lng": round(lng, 6),
                "accuracy_m": random.uniform(5, 25),
                "speed_kmh": round(speed, 1),
                "bearing": random.randint(0, 360),
                "route_id": route_id,
                "direction": direction,
                "sequence": get_nearest_sequence(lat, lng)
            },
            timeout=5.0
        )
        return response.status_code == 200
    except Exception as e:
        print(f"  Error sending ping: {e}")
        return False


async def run_simulation(api_url: str, speed_kmh: float, loop: bool):
    """Run the GPS simulation."""
    interval_seconds = 10
    avg_speed = speed_kmh

    print(f"Starting GPS simulation on Line 1")
    print(f"  Speed: {avg_speed} km/h")
    print(f"  Ping interval: {interval_seconds}s")
    print(f"  Packet loss: {PACKET_LOSS_RATE*100}%")
    print("-" * 50)

    device_token = f"sim-tram-{random.randint(10000, 99999)}"
    direction = 0
    route_id = 1

    while True:
        for i in range(len(STATIONS_LINE1) - 1):
            from_lat, from_lng = STATIONS_LINE1[i]
            to_lat, to_lng = STATIONS_LINE1[i + 1]

            dist_km = math.sqrt((to_lat - from_lat)**2 + (to_lng - from_lng)**2) * 111
            travel_time_s = (dist_km / avg_speed) * 3600
            pings_per_segment = max(1, int(travel_time_s / interval_seconds))

            for p in range(pings_per_segment + 1):
                t = p / pings_per_segment if pings_per_segment > 0 else 1
                lat, lng = interpolate_position(from_lat, from_lng, to_lat, to_lng, min(t, 1))
                lat, lng = add_noise(lat, lng)

                success = await send_gps_ping(
                    httpx.AsyncClient(), lat, lng, route_id, direction, avg_speed, device_token
                )

                station_num = i + 1
                status = "OK" if success else "LOST"
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Station {station_num}/32 | {status}")

                if p < pings_per_segment:
                    await asyncio.sleep(interval_seconds)

            await asyncio.sleep(1)

        print(f"\nCompleted full line traversal at {datetime.now().strftime('%H:%M:%S')}")
        if not loop:
            break
        await asyncio.sleep(5)
        direction = 1 - direction
        print(f"Reversing direction to {direction}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tram Alger GPS Simulator")
    parser.add_argument("--api", default="http://localhost:8000", help="API base URL")
    parser.add_argument("--speed", type=float, default=22.0, help="Average tram speed in km/h")
    parser.add_argument("--loop", action="store_true", help="Loop continuously")
    args = parser.parse_args()

    try:
        asyncio.run(run_simulation(args.api, args.speed, args.loop))
    except KeyboardInterrupt:
        print("\nSimulation stopped.")
