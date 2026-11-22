#!/usr/bin/env python3
"""One-off preflight: discover how to import authorized official MUL data."""
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import re
BASE = "https://masterunitlist.battletech.com"
URLS = ["/robots.txt", "/sitemap.xml", "/", "/units/atlas-as7-d", "/units/mad-cat-timber-wolf-prime"]
for suffix in URLS:
    print("CHECK", suffix, flush=True)
    try:
        with urlopen(Request(BASE+suffix, headers={"User-Agent":"BtechMobile-Availability-Research/0.1 (+https://github.com/drag0nblad3/BtechMobile)"}), timeout=20) as response:
            data=response.read(2_000_000).decode("utf-8","replace")
            print("STATUS",response.status,"TYPE",response.headers.get("content-type"),"BYTES",len(data), flush=True)
            if suffix=="/robots.txt":
                print("ROBOTS_BEGIN", data[:5000], "ROBOTS_END", flush=True)
            if suffix=="/sitemap.xml":
                print("SITEMAP_HEAD",data[:800],flush=True)
            if suffix=="/":
                print("SCRIPT_SRCS",re.findall(r'<script[^>]*src="([^"]+)"',data)[:35],flush=True)
                print("INDEX_REFERENCES", re.findall(r'[^"\s<>]{0,90}(?:units\.json|unit-index|search-index|\.json)[^"\s<>]{0,90}',data,re.I)[:20],flush=True)
                print("HTML_HEAD",data[:1100],flush=True)
            if suffix.startswith("/units/"):
                print("HAS_TABLE", "Faction" in data and "Era" in data, "FRACTION", data.find("Faction"),flush=True)
                print("HTML_HEAD",data[:900],flush=True)
    except Exception as exc: print("ERROR",repr(exc),flush=True)
