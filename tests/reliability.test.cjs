// Run: node --test tests/reliability.test.cjs (no npm dependencies).
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../SKAPA_Reliability_Design_v0.1.0.html'),'utf8');
const code=html.match(/<script id="reliability-engine">([\s\S]*?)<\/script>/)[1];
const context={module:{exports:{}},setTimeout};vm.runInNewContext(code,context);
const R=context.module.exports;
const p={Hs:5,T:13,hp:9,Dn:.8326,rhoR:2.65,rhoW:1.03,cot:2,KD:2.9,DN:1,N:500,BM:8,BMp:4,angle:0,section:'trunk',nso:'thesis',target:10,cov:[18,3.8,6.7,10,10,16,50]};
const close=(a,b,t=1e-6)=>assert.ok(Math.abs(a-b)<t,`${a} != ${b}`);
test('normal CDF and quantiles preserve tails and round-trip',()=>{
  for(const u of [-6,-3,-1,0,1,3,6])close(R.inv(R.cdf(u)),u,1e-6);
  close(R.cdf(-3),.0013498980316301,1e-9);
});
test('deterministic values match thesis table 3.5 rounding',()=>{
  const d=R.deterministic(p);close(d.L,117.7757321993);close(d.k,.1476,5e-5);close(d.ns,3.8181,1.1e-4);close(d.requiredDn,.8326,1e-5);close(d.W,1.5296,2e-4);
});
test('FORM design point agrees with independent SciPy SLSQP calculation',()=>{
  const r=R.form(p);close(r.beta,.094619478145,2e-6);close(r.pf,.462308538963,2e-7);
  assert.ok(Math.abs(r.g)<1e-6);close(r.alpha.reduce((s,v)=>s+v*v,0),1,1e-10);
  const independent=[-.06343375,-.01324532,-.02337846,.01639342,-.03302525,.05193206,.01227447];
  r.u.forEach((v,i)=>close(v,independent[i],2e-6));
  assert.ok(r.history.length>1&&r.converged);
});
test('target design meets target and decreases Pf with larger diameter',()=>{
  const target=R.targetDiameter(p);close(target.dn,1.1720127371,1e-6);
  assert.ok(target.pf<=.1&&target.dn>p.Dn);assert.ok(R.form({...p,Dn:.6}).pf>R.form(p).pf);
  const low=R.form({...p,Dn:.6});assert.ok(low.beta<0&&low.pf>.5);
});
test('shape branches and common model coefficient are applied consistently',()=>{
  const head=R.deterministic({...p,section:'head',angle:60});close(head.k2,.703125);
  close(R.deterministic({...p,section:'head',angle:0}).k2,.2205);
  const a=R.deterministic({...p,nso:'hudson',KD:7.3});close(a.nso,Math.cbrt(14.6));
  const g=R.limit(a.means,{...p,nso:'hudson',KD:7.3},a);
  close(g,p.rhoR/p.rhoW*p.Dn*a.nsStar-p.Dn*a.nsStar-p.Hs);
});
test('reject invalid inputs and absent stochastic variation',()=>{
  for(const change of [{Hs:0},{Dn:NaN},{rhoR:1},{angle:65},{BM:0},{cov:[0,0,0,0,0,0,0]},{target:50}])assert.throws(()=>R.form({...p,...change}));
});
test('positive truncation and tiny-N resistance preserve full sample classification',()=>{
  const d=R.deterministic(p);
  const x=R.transform([0,0,0,0,0,0,-6],p,d);assert.ok(x[6]>0);
  const nearZero=d.means.slice();nearZero[6]=1e-10;assert.ok(R.limit(nearZero,p,d)>0);
  const negativeResistance=d.means.slice();negativeResistance[0]=-.1;assert.ok(R.limit(negativeResistance,p,d)<0);
});
test('MCS seeded reference, sample accounting, CI and truncated-normal moments',async()=>{
  const r=await R.monteCarlo(p,100000,2026);assert.equal(r.failed,45956);assert.equal(r.invalid,0);close(r.pf,.45956,1e-10);
  assert.ok(r.lower<r.pf&&r.upper>r.pf);assert.ok(r.lower<R.form(p).pf&&r.upper>R.form(p).pf);
  assert.equal(r.histogram.reduce((a,b)=>a+b,0)+r.underflow+r.overflow,100000);
  close(r.moments.Hs.mean,5,.012);close(r.moments.N.mean,513.812,.9);
  assert.equal(r.convergence.at(-1).count,r.count);assert.equal(r.convergence.at(-1).failed,r.failed);
});
test('Monte.m DN=5 preset and deterministic seeded repeatability',async()=>{
  const a=await R.monteCarlo({...p,DN:5},1000,2026),b=await R.monteCarlo({...p,DN:5},1000,2026);
  assert.equal(a.failed,b.failed);assert.ok(a.pf<.2);assert.equal(a.invalid,0);
});
test('invalid physical samples never produce a reported conditional Pf',async()=>{
  const cov=p.cov.slice();cov[3]=100;const r=await R.monteCarlo({...p,cov},1000,2026);
  assert.ok(r.invalid>0);assert.equal(r.pf,null);assert.equal(r.lower,null);
});
