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
