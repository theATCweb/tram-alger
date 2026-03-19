"""
Database seeder for Tram Alger Line 1.
Seeds all 32 stations and schedule data.
"""
import asyncio
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

import asyncpg


STATIONS_LINE1 = [
    ("Bir Mourad Raïs",     "بئر مراد رايس",       36.7356, 3.0490,  1,  True),
    ("Les Fusillés",         "المحكومون",            36.7381, 3.0528,  2,  False),
    ("Dergana",              "درقانة",               36.7401, 3.0569,  3,  False),
    ("Bab Ezzouar",          "باب الزوار",           36.7424, 3.0611,  4,  False),
    ("Ruisseau",             "الواد الروشا",         36.7449, 3.0652,  5,  False),
    ("Aïn Naadja",           "عين نعجة",             36.7475, 3.0695,  6,  False),
    ("Caroubier",            "الخروبة",              36.7501, 3.0738,  7,  False),
    ("Oued Ouchayah",        "وادي أوشايا",          36.7529, 3.0782,  8,  False),
    ("Soustara",             "سوسترا",               36.7558, 3.0826,  9,  False),
    ("Les Ateliers",         "الورشات",              36.7587, 3.0869, 10,  False),
    ("La Glacière",          "الثلاجة",              36.7613, 3.0911, 11,  False),
    ("Belouizdad",           "بلوزداد",              36.7638, 3.0953, 12,  False),
    ("Sidi M'hamed",         "سيدي محمد",            36.7664, 3.0996, 13,  False),
    ("Khelifa Boukhalfa",    "خليفة بوخلفة",         36.7689, 3.1038, 14,  False),
    ("Place des Martyrs",    "ساحة الشهداء",         36.7715, 3.1080, 15,  False),
    ("Tafourah Grande Poste","تافورة",               36.7741, 3.1122, 16,  False),
    ("Aïn Beïda",            "عين بيضاء",            36.7766, 3.1165, 17,  False),
    ("Hamma",                "الحامة",               36.7792, 3.1207, 18,  False),
    ("Ahmed Francis",        "أحمد فرانسيس",         36.7818, 3.1250, 19,  False),
    ("El Mohammadia",        "المحمدية",             36.7843, 3.1292, 20,  False),
    ("Aissat Idir",          "عيسات إيدير",          36.7869, 3.1334, 21,  False),
    ("Mer et Soleil",        "بحر وشمس",             36.7894, 3.1377, 22,  False),
    ("Oued El Had",          "وادي الحد",            36.7920, 3.1419, 23,  False),
    ("Caroubier Deux",       "الخروبة 2",            36.7945, 3.1461, 24,  False),
    ("Maqam Echahid",        "مقام الشهيد",          36.7971, 3.1504, 25,  False),
    ("Le Marché",            "السوق",                36.7996, 3.1546, 26,  False),
    ("Garidi",               "قريدي",                36.8022, 3.1588, 27,  False),
    ("Cinq Maisons",         "خمسة بيوت",            36.8047, 3.1631, 28,  False),
    ("Bachdjerrah",          "باش جراح",             36.8073, 3.1673, 29,  False),
    ("Bab Ezzouar Deux",     "باب الزوار 2",         36.8098, 3.1715, 30,  False),
    ("Birtouta",             "بئر توتة",             36.8124, 3.1758, 31,  False),
    ("El Harrach Centre",    "الحراش المركز",        36.8149, 3.1800, 32,  True),
]


async def seed_database():
    """Seed the database with routes, stations, and schedule."""
    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(db_url)

    try:
        existing = await conn.fetchval("SELECT COUNT(*) FROM stations")
        if existing > 0:
            print(f"Database already has {existing} stations. Skipping seed.")
            return

        route_id_out = await conn.fetchval("""
            INSERT INTO routes (name, short_name, direction, is_active)
            VALUES ('Tramway Alger Ligne 1', 'T1', 0, true) RETURNING id
        """)
        route_id_in = await conn.fetchval("""
            INSERT INTO routes (name, short_name, direction, is_active)
            VALUES ('Tramway Alger Ligne 1', 'T1', 1, true) RETURNING id
        """)

        print(f"Created routes: outbound={route_id_out}, inbound={route_id_in}")

        station_ids_out = []
        station_ids_in = []
        for name, name_ar, lat, lng, seq, is_terminal in STATIONS_LINE1:
            sid_out = await conn.fetchval("""
                INSERT INTO stations (name, name_ar, lat, lng, sequence, route_id, is_terminal)
                VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id
            """, name, name_ar, lat, lng, seq, route_id_out, is_terminal)
            station_ids_out.append(sid_out)

            sid_in = await conn.fetchval("""
                INSERT INTO stations (name, name_ar, lat, lng, sequence, route_id, is_terminal)
                VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id
            """, name, name_ar, lat, lng, seq, route_id_in, is_terminal)
            station_ids_in.append(sid_in)

        print(f"Inserted {len(station_ids_out)} stations each direction")

        schedule_count = 0
        for direction, r_id, ids in [
            (0, route_id_out, station_ids_out),
            (1, route_id_in,  station_ids_in),
        ]:
            for station_idx, sid in enumerate(ids):
                base_min = 5 * 60 + 30
                interval_min = 6
                start_offset = station_idx * 2
                first_tram_min = base_min + start_offset

                for tram_num in range(176):
                    arrival_min = first_tram_min + tram_num * interval_min
                    if arrival_min > 23 * 60:
                        break
                    await conn.execute("""
                        INSERT INTO schedule (station_id, route_id, direction, arrival_min, day_mask)
                        VALUES ($1, $2, $3, $4, 127)
                    """, sid, r_id, direction, arrival_min)
                    schedule_count += 1

        print(f"Inserted {schedule_count} schedule entries")
        print("Database seeding complete!")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(seed_database())
