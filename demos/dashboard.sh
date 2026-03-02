#!/bin/sh
# kombify StackKits — Dynamic Dashboard Service
# Discovers services from Traefik API and renders a self-configuring dashboard.
#
# Configuration via environment variables (set by stackkit generate / compose):
#   STACKKIT_NAME     - Kit display name (e.g. "kombify Base Kit")
#   STACKKIT_COLOR    - Accent color hex (e.g. "#3b82f6")
#   STACKKIT_API_PORT - Traefik API host port (e.g. "7090")
#   STACKKIT_REGISTRY - JSON array of service metadata:
#     [{"r":"router-name","n":"Display Name","d":"Description","l":"L1|L2|L3","nd":"node-id"}, ...]
#
# LAN access: When accessed via IP, service links use sslip.io for automatic
# DNS resolution (e.g. whoami.192.168.1.50.sslip.io -> 192.168.1.50).
# No /etc/hosts or local DNS setup required.
set -e

echo "[dashboard] Waiting for Traefik API..."
RDATA="[]"
RETRIES=30
while [ "$RETRIES" -gt 0 ]; do
  if RDATA=$(wget -qO- http://traefik:8080/api/http/routers 2>/dev/null); then
    echo "[dashboard] Traefik API ready"
    break
  fi
  RETRIES=$((RETRIES - 1))
  sleep 2
done

if [ "$RDATA" = "[]" ]; then
  echo "[dashboard] Warning: Traefik API unreachable, dashboard will show no services"
fi

# Write data files for the frontend
printf '%s' "$RDATA" > /usr/share/nginx/html/routers.json

printf '{"name":"%s","color":"%s","apiPort":"%s","registry":%s}\n' \
  "${STACKKIT_NAME:-StackKit}" \
  "${STACKKIT_COLOR:-#3b82f6}" \
  "${STACKKIT_API_PORT:-8080}" \
  "${STACKKIT_REGISTRY:-[]}" \
  > /usr/share/nginx/html/config.json

# Write the dashboard HTML (fully static template — all dynamic logic is in JS)
cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>StackKit Dashboard</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:system-ui,-apple-system,sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;padding:1.5rem 2rem}
.hdr{margin-bottom:1.5rem;border-bottom:1px solid #334155;padding-bottom:1rem}
.kit{font-size:.85rem;font-weight:600;margin-bottom:.15rem}
h1{font-size:1.4rem;color:#e2e8f0;margin-bottom:.25rem}
.meta{font-size:.75rem;color:#64748b}
.info{background:#1e293b;border:1px solid #334155;border-radius:.4rem;padding:.6rem .8rem;margin-bottom:1rem;font-size:.75rem;color:#94a3b8}
.info code{background:#1c1917;padding:.1rem .3rem;border-radius:.2rem;font-family:monospace;font-size:.7rem}
.info a{color:#60a5fa}
.ng{margin-bottom:1.5rem}
.nh{font-size:.85rem;font-weight:700;color:#e2e8f0;margin-bottom:.5rem;padding-bottom:.4rem;border-bottom:2px solid #334155;display:flex;align-items:center;gap:.5rem}
.nb{font-size:.55rem;padding:.15rem .35rem;border-radius:.2rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.lh{font-size:.7rem;text-transform:uppercase;letter-spacing:.06em;color:#94a3b8;margin:.5rem 0 .3rem .15rem}
table{width:100%;border-collapse:collapse;margin-bottom:.5rem}
th{text-align:left;font-size:.65rem;text-transform:uppercase;letter-spacing:.06em;color:#64748b;padding:.35rem .6rem;border-bottom:1px solid #334155}
td{padding:.45rem .6rem;border-bottom:1px solid #1e293b;font-size:.78rem}
tr:hover{background:#1e293b}
.tg{font-size:.6rem;padding:.12rem .3rem;border-radius:.15rem;font-weight:600}
.tl1{background:#3b1e1e;color:#f87171}
.tl2{background:#1e3a5f;color:#60a5fa}
.tl3{background:#1e3a2f;color:#4ade80}
.ta{background:#3b1e5f;color:#c084fc}
a{text-decoration:none}a:hover{text-decoration:underline}
.nl{color:#64748b}
.ld{text-align:center;padding:3rem;color:#64748b}
footer{margin-top:1.5rem;padding-top:.75rem;border-top:1px solid #1e293b;color:#475569;font-size:.65rem;display:flex;justify-content:space-between}
</style></head><body>
<div class="hdr">
<div class="kit" id="kit"></div>
<h1 id="title">Loading...</h1>
<div class="meta" id="meta"></div>
</div>
<div id="warn"></div>
<div id="svc"><div class="ld">Discovering services...</div></div>
<footer><span>kombify StackKits</span><span id="ai"></span></footer>
<script>
(function(){
  var h=location.hostname, p=location.port, pr=location.protocol;
  var isD=h.indexOf(".")>-1 && !/^\d+\.\d+\.\d+\.\d+$/.test(h);

  function mkUrl(traefikHost){
    if(!traefikHost) return null;
    var sub=traefikHost.split(".")[0];
    if(isD){
      var a=h.split(".");
      a[0]=sub;
      return pr+"//"+a.join(".")+(p?":"+p:"");
    }
    // IP-based access: use sslip.io for automatic DNS resolution
    return pr+"//"+sub+"."+h+".sslip.io"+(p?":"+p:"");
  }

  Promise.all([
    fetch("/config.json").then(function(r){return r.json()}),
    fetch("/routers.json").then(function(r){return r.json()})
  ]).then(function(res){
    var cfg=res[0], R=res[1];
    var G=cfg.registry||[];

    document.title=cfg.name+" Dashboard";
    document.getElementById("kit").textContent=cfg.name;
    document.getElementById("kit").style.color=cfg.color;

    function apiUrl(){
      if(isD){var a=h.split(".");a[0]="proxy";return pr+"//"+a.join(".")+(p?":"+p:"")}
      return pr+"//proxy."+h+".sslip.io"+(p?":"+p:"");
    }

    // Parse Traefik routers into service list
    var svcs=[];
    for(var i=0;i<R.length;i++){
      var r=R[i], rn=(r.name||"").replace(/@.*/,"");
      if(rn==="default-fallback"||rn==="dashboard"||/-lan$/.test(rn)) continue;
      var rm=r.rule && r.rule.match(/Host\(`([^`]+)`\)/);
      if(!rm) continue;
      var rh=rm[1];
      if(rh==="localhost") continue;
      var mt=null;
      for(var j=0;j<G.length;j++){if(G[j].r===rn){mt=G[j];break}}
      var mw=r.middlewares||[];
      var au=false;
      for(var k=0;k<mw.length;k++){if(mw[k].indexOf("tinyauth")>-1) au=true}
      svcs.push({id:rn, n:mt?mt.n:rn, d:mt?mt.d:"", l:mt?mt.l:"", nd:mt?mt.nd:"main", host:rh, url:mkUrl(rh), au:au});
    }

    // Add L1 foundation services from registry (no Traefik routers)
    for(var j=0;j<G.length;j++){
      if(G[j].l==="L1") svcs.push({id:G[j].n, n:G[j].n, d:G[j].d, l:"L1", nd:G[j].nd||"main", host:"", url:null, au:false});
    }

    // Group services by node
    var nds={}, no=[];
    for(var i=0;i<svcs.length;i++){
      var nd=svcs[i].nd;
      if(!nds[nd]){nds[nd]=[];no.push(nd)}
      nds[nd].push(svcs[i]);
    }

    var nc=no.length;
    var tp={1:"Single Node",2:"2-Node Topology",3:"3-Node Topology"};
    document.getElementById("title").textContent=tp[nc]||(nc+"-Node Topology");
    document.getElementById("meta").textContent=nc+" node"+(nc>1?"s":"")+
      " \u00b7 "+svcs.length+" services";
    document.getElementById("ai").textContent="via "+h+(p?":"+p:"");

    if(!isD){
      document.getElementById("warn").innerHTML=
        '<div class="info">Accessing via <code>'+h+(p?":"+p:"")+'</code> \u2014 '+
        'service links use <a href="https://sslip.io" target="_blank">sslip.io</a> for automatic DNS resolution. '+
        'Works from any device on your network.</div>';
    }

    var bc={main:["#451a03","#fbbf24"],cloud:["#164e63","#22d3ee"],local:["#14532d","#4ade80"],
            worker1:["#172554","#60a5fa"],worker2:["#1e3a5f","#38bdf8"]};
    var bl={main:"Main",cloud:"Cloud",local:"Local",worker1:"Worker 1",worker2:"Worker 2"};

    function tbl(items,lbl){
      if(!items.length) return "";
      var o='<div class="lh">'+lbl+'</div><table><tr><th>Service</th><th>Role</th><th>Layer</th><th>Host Rule</th></tr>';
      for(var x=0;x<items.length;x++){
        var v=items[x];
        var lk=v.url
          ? '<a href="'+v.url+'" target="_blank" style="color:'+cfg.color+'">'+v.n+'</a>'
          : '<span class="nl">'+v.n+'</span>';
        var lt=v.l==="L1"?'<span class="tg tl1">L1</span>':v.l==="L2"?'<span class="tg tl2">L2</span>':'<span class="tg tl3">L3</span>';
        o+='<tr><td>'+lk+'</td><td>'+v.d+(v.au?' <span class="tg ta">auth</span>':'')+'</td><td>'+lt+'</td><td><code style="font-size:.7rem;color:#64748b">'+(v.host||'\u2014')+'</code></td></tr>';
      }
      return o+'</table>';
    }

    var out="";
    for(var ni=0;ni<no.length;ni++){
      var nd=no[ni], ns=nds[nd], c=bc[nd]||["#334155","#e2e8f0"], lb=bl[nd]||nd;
      out+='<div class="ng">';
      if(nc>1) out+='<div class="nh"><span class="nb" style="background:'+c[0]+';color:'+c[1]+'">'+lb+'</span> '+nd.charAt(0).toUpperCase()+nd.slice(1)+' Node</div>';
      var l1=[],l2=[],l3=[];
      for(var si=0;si<ns.length;si++){if(ns[si].l==="L1") l1.push(ns[si]); else if(ns[si].l==="L2") l2.push(ns[si]); else l3.push(ns[si])}
      out+=tbl(l1,"Foundation Services (L1)");
      out+=tbl(l2,"Platform Services (L2)");
      out+=tbl(l3,"Application Services (L3)");
      out+='</div>';
    }
    out+='<div style="margin-top:.75rem;font-size:.72rem;color:#64748b">Traefik Dashboard: <a href="'+apiUrl()+'" target="_blank" style="color:'+cfg.color+'">'+apiUrl()+'</a></div>';
    document.getElementById("svc").innerHTML=out;

  }).catch(function(err){
    document.getElementById("svc").innerHTML='<div class="ld" style="color:#ef4444">Failed to load: '+err.message+'</div>';
  });
})();
</script>
</body></html>
HTMLEOF

echo "[dashboard] Ready"
exec nginx -g "daemon off;"
