import json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
import numpy as np
from scipy.stats import norm,gumbel_r,truncnorm
from scipy.optimize import minimize
p=dict(Hs=5,T=13,hp=9,Dn=.8326,rhoR=2.65,rhoW=1.03,cot=2,KD=2.9,DN=1,N=500,BM=8,BMp=4,angle=0,section='trunk',nso='thesis',target=10,cov=[18,3.8,6.7,10,10,16,50])
js="const fs=require('fs'),vm=require('vm');const html=fs.readFileSync("+json.dumps(str(ROOT/'SKAPA_Reliability_Design_v0.1.0.html'))+",'utf8');const code=html.match(/<script id=\"reliability-engine\">([\\s\\S]*?)<\\/script>/)[1];const c={module:{exports:{}},setTimeout};vm.runInNewContext(code,c);const R=c.module.exports;const p="+json.dumps(p)+";console.log(JSON.stringify(R.form(p)));"
r=json.loads(subprocess.check_output(['node','-e',js]))
mu=np.array(r['d']['means']);sig=mu*np.array(p['cov'])/100

def transform(u):
 x=mu+sig*u
 x[5]=gumbel_r.ppf(norm.cdf(u[5]),loc=mu[5]-.5772156649015329*sig[5]*np.sqrt(6)/np.pi,scale=sig[5]*np.sqrt(6)/np.pi)
 x[6]=truncnorm.ppf(norm.cdf(u[6]),-mu[6]/sig[6],np.inf,loc=mu[6],scale=sig[6])
 return x

def g(u):
 ah,delta,dn,k,ratio,hs,n=transform(u)
 if k<=0 or k>=1 or n<=0:return -1e10
 ns=1.3*(1-k)/k**(1/3)*ratio+1.8*np.exp(-1.5*(1-k)**2/k**(1/3)*ratio)
 return ah*delta*dn*np.exp(.25*(np.log(p['DN'])-.3+150/n))*ns-hs
out=minimize(lambda u:.5*np.dot(u,u),np.zeros(7),constraints=[{'type':'eq','fun':g}],method='SLSQP',options={'ftol':1e-12,'maxiter':300})
assert out.success,out.message
beta=np.linalg.norm(out.x)
assert abs(beta-r['beta'])<2e-6
assert np.max(np.abs(out.x-np.array(r['u'])))<2e-5
print('Independent SciPy constrained optimization: beta',beta,'Pf',norm.cdf(-beta),'max design-point difference',np.max(np.abs(out.x-np.array(r['u']))))
print('Limit residual',g(out.x))
