from urllib.request import Request,urlopen
import re
ROOT="https://masterunitlist.battletech.com"
agent={"User-Agent":"BtechMobile-MUL-Research/1.0 (+https://github.com/drag0nblad3/BtechMobile)"}
for path in ("/build/assets/app-CHhBmoSO.js","/"):
    with urlopen(Request(ROOT+path,headers=agent),timeout=20) as r:
        src=r.read(500000).decode("utf8","replace")
    print("RESOURCE",path,"LENGTH",len(src))
    words=["index","search","units","faction","json","fetch(","axios","available","records","api/"]
    for w in words:
        matches=[m.start() for m in re.finditer(re.escape(w),src,re.I)]
        print("TERM",repr(w),"COUNT",len(matches))
        for at in matches[:12]:
            print("SNIPPET",repr(src[max(0,at-95):at+160]))
    quoted=re.findall(r'["\x27]([^"\x27]{4,120})["\x27]',src)
    print("LINKLIKE",[(q[:120]) for q in quoted if "/" in q and any(w in q for w in ["unit","search","index",".json","api"] )][:70])

print("BEGIN STATIC INDEX")
import json
from urllib.parse import urljoin
from time import sleep
robots_delay=10.1
with urlopen(Request(ROOT+"/data/manifest.json",headers=agent),timeout=35) as r:
    manifest=json.loads(r.read(1000000))
print("MANIFEST",json.dumps(manifest)[:4500],flush=True)
files=manifest.get("files",{})
for kind in ("units","availability","factions","eras"):
    if kind not in files:continue
    url=ROOT+"/data/"+files[kind]
    sleep(robots_delay)
    with urlopen(Request(url,headers=agent),timeout=45) as r:
        blob=r.read(35000000)
        print("BULK_FILE",kind,"LENGTH",len(blob),"CONTENT_TYPE",r.headers.get("content-type"),flush=True)
    try:
        data=json.loads(blob)
    except Exception as e:
        print("PARSE_FAILED",kind,str(e),"HEAD",repr(blob[:100]),flush=True);continue
    print("BULK_SUMMARY",kind,"KIND",type(data).__name__,"SIZE",len(data),flush=True)
    if kind=="units":
        print("FIRST_UNITS",json.dumps(data[:3])[:2500],flush=True)
        hits=[x for x in data if str(x.get("id")) in ("140","1901","1985","8497","1980")]
        print("ID_MATCHES",json.dumps(hits)[:5000],flush=True)
    elif kind=="availability":
        print("AVAIL_KEYS",list(data)[:30],flush=True)
        for k,v in data.items():
            print("AVAIL_PART",k,"TYPE",type(v).__name__,"SIZE",len(v),"SAMPLE",json.dumps(v if len(v)<3 else (list(v.items())[:2] if isinstance(v,dict) else v[:2]))[:5000],flush=True)
    else:
        print("VOCAB_SAMPLE",json.dumps(data[:5] if isinstance(data,list) else {k:v[:4] if isinstance(v,list) else v for k,v in list(data.items())[:3]})[:3000],flush=True)
