import asyncio
import sys
import os
from services.tigergraph_service import tg_service

async def main():
    print("\n" + "="*40)
    print("      TIGERGRAPH CONNECTION TEST")
    print("="*40)
    
    print(f"-> Demo Mode Active : {tg_service.is_demo}")
    
    if tg_service.is_demo:
        print("-> Connection Status: ⚠️ USING LOCAL FAKE DATA")
    else:
        print(f"-> Connection Status: ✅ CONNECTED LIVE")
        print(f"-> Host URL         : {tg_service._host}")
        
    print("\n" + "="*40)
    print("      FETCHING SAMPLE DATA")
    print("="*40)
    
    try:
        stations = await tg_service.get_all_stations()
        print(f"-> Total Stations Found: {len(stations)}")
        if stations:
            print(f"-> Sample Station Data:")
            print("   " + str(stations[0]))
    except Exception as e:
        print(f"-> ❌ Error fetching stations: {e}")
        
    print("\n" + "="*40)

if __name__ == "__main__":
    asyncio.run(main())
