from pathlib import Path
from playwright.sync_api import sync_playwright
import json
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
from functools import partial
from threading import Thread
root=Path(__file__).resolve().parents[1]
server=ThreadingHTTPServer(('127.0.0.1',0),partial(SimpleHTTPRequestHandler,directory=str(root)))
Thread(target=server.serve_forever,daemon=True).start()
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
 page=browser.new_page(viewport={'width':1600,'height':1100},device_scale_factor=1)
 errors=[];page.on('pageerror',lambda error:errors.append(str(error)))
 page.goto(f'http://127.0.0.1:{server.server_port}/SKAPA_Reliability_Design_v0.1.0.html')
 page.click('#thesisPreset');page.click('#calculate');assert page.locator('#statusText').inner_text()=='AFDA 수렴 완료'
 print('thesis',page.locator('#pf').inner_text(),page.locator('#beta').inner_text())
 page.click('#design');page.wait_for_function("!document.getElementById('design').disabled")
 assert '1.17201' in page.locator('#designResult').inner_text()
 page.click('#mcs');page.wait_for_function("!document.getElementById('mcs').disabled",timeout=60000)
 print('mcs',page.locator('#mcsResult').inner_text());assert '45.956%' in page.locator('#mcsResult').inner_text()
 assert page.locator('#mcsCharts').is_visible()
 assert page.locator('#mcsConvergence polygon[data-ci="95"]').count()==1
 assert page.locator('#mcsConvergence circle title').count()==100
 assert page.locator('#mcsHistogram rect title').count()==40
 assert page.locator('#mcsComparison path[data-ci="95"]').count()==1
 assert '45.956%' in page.locator('#mcsComparison').text_content()
 assert page.locator('#mcsCharts').evaluate("e=>!e.innerHTML.includes('NaN')")
 with page.expect_download() as info:page.click('#csv')
 download=info.value;assert download.suggested_filename=='SKAPA_Reliability_Design.csv'
 csv=Path(download.path()).read_text(encoding='utf-8-sig');assert 'AFDA Pf' in csv and 'MCS' in csv and '목표 설계' in csv
 Path('/tmp/skapa-reliability-artifacts').mkdir(exist_ok=True)
 page.screenshot(path='/tmp/skapa-reliability-artifacts/SKAPA_Reliability_Design_desktop.png',full_page=True)
 page.locator('#mcsCharts').screenshot(path='/tmp/skapa-reliability-artifacts/SKAPA_MonteCarlo_graphs.png')
 page.set_viewport_size({'width':390,'height':844})
 assert page.locator('#mcsCharts').is_visible()
 assert page.evaluate('document.documentElement.scrollWidth<=window.innerWidth')
 page.set_viewport_size({'width':1600,'height':1100})
 page.pdf(path='/tmp/skapa-reliability-artifacts/SKAPA_Reliability_Design_report.pdf',print_background=True)
 page.fill('#Hs','0');assert page.locator('#pf').inner_text()=='—';page.click('#calculate');assert page.locator('#message').inner_text();assert page.locator('#csv').is_disabled()
 page.click('#montePreset');assert page.locator('#DN').input_value()=='5';assert page.locator('#samples').input_value()=='61000'
 page.click('#calculate');page.click('#mcs');page.wait_for_function("!document.getElementById('mcs').disabled",timeout=60000)
 print('Monte.m',page.locator('#mcsResult').inner_text())
 page.click('#matlabPreset');page.click('#calculate');assert page.locator('#statusText').inner_text()=='AFDA 수렴 완료'
 print('MATLAB',page.locator('#pf').inner_text())
 page.fill('#cov3','100');page.click('#calculate')
 if page.locator('#mcs').is_enabled():
  page.fill('#samples','1000');page.click('#mcs');page.wait_for_function("!document.getElementById('mcs').disabled",timeout=60000)
  assert '확정하지 않습니다' in page.locator('#mcsResult').inner_text()
 page.click('#thesisPreset');page.click('#calculate')
 page.fill('#project','<img src=x onerror=alert(1)>');assert page.locator('#pf').inner_text()=='—';page.click('#calculate');assert page.locator('#resultNote img').count()==0
 page.fill('#project','혼성 방파제 신뢰성 검토');page.click('#calculate')
 page.set_viewport_size({'width':390,'height':844});page.screenshot(path='/tmp/skapa-reliability-artifacts/SKAPA_Reliability_Design_mobile.png',full_page=True)
 assert page.evaluate('document.documentElement.scrollWidth<=window.innerWidth')
 assert not errors,errors
 print('browser assertions passed; CSV, PDF, desktop/mobile, presets, validation, stale-result clearing; no JS errors')
 browser.close()
server.shutdown()
