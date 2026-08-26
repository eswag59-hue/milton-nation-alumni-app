/* Store badges drawn to the familiar proportions. These are stand-ins so the
   end card composes correctly — swap Apple's and Google's official artwork in
   before anything ships publicly, since both have brand guidelines. */
function storeBadge(g, cx, cy, w, kind){
  const h = w*0.295, r = h*0.17;
  g.save();
  g.fillStyle = '#000000';
  g.beginPath(); g.roundRect(cx-w/2, cy-h/2, w, h, r); g.fill();
  g.strokeStyle = 'rgba(255,255,255,.55)'; g.lineWidth = Math.max(w*0.006,1.5);
  g.beginPath(); g.roundRect(cx-w/2, cy-h/2, w, h, r); g.stroke();
  const mx = cx-w/2 + h*0.62, my = cy;
  const tx = cx-w/2 + h*1.12;
  g.textAlign='left';
  if(kind==='apple'){
    g.fillStyle='#FFFFFF';
    g.save(); g.translate(mx,my); const s=h*0.56;
    g.beginPath();
    g.ellipse(-s*0.20,s*0.02,s*0.34,s*0.46,0,0,6.283);
    g.ellipse( s*0.20,s*0.02,s*0.34,s*0.46,0,0,6.283);
    g.fill();
    g.beginPath(); g.ellipse(s*0.06,-s*0.56,s*0.13,s*0.21,0.55,0,6.283); g.fill();
    g.restore();
    g.font=`400 ${h*0.20}px Jost, system-ui, sans-serif`;
    g.fillStyle='rgba(255,255,255,.92)';
    g.fillText('Download on the', tx, cy-h*0.11);
    g.font=`500 ${h*0.34}px Jost, system-ui, sans-serif`;
    g.fillStyle='#FFFFFF';
    g.fillText('App Store', tx, cy+h*0.26);
  } else {
    g.save(); g.translate(mx,my); const s=h*0.56;
    const tri=[[-s*0.40,-s*0.62],[s*0.52,0],[-s*0.40,s*0.62]];
    const cols=['#EA4335','#FBBC04','#34A853','#4285F4'];
    for(let i=0;i<4;i++){
      g.save();
      g.beginPath(); g.rect(-s*0.5, -s*0.7+i*s*0.35, s*1.1, s*0.35); g.clip();
      g.fillStyle=cols[i];
      g.beginPath(); g.moveTo(tri[0][0],tri[0][1]); g.lineTo(tri[1][0],tri[1][1]);
      g.lineTo(tri[2][0],tri[2][1]); g.closePath(); g.fill();
      g.restore();
    }
    g.restore();
    g.font=`400 ${h*0.19}px Jost, system-ui, sans-serif`;
    g.fillStyle='rgba(255,255,255,.92)';
    g.fillText('GET IT ON', tx, cy-h*0.11);
    g.font=`500 ${h*0.34}px Jost, system-ui, sans-serif`;
    g.fillStyle='#FFFFFF';
    g.fillText('Google Play', tx, cy+h*0.26);
  }
  g.textAlign='center';
  g.restore();
}
