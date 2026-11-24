'use strict';
const baseTelemetry = window.receiveTelemetry;
function renderNerd(d) {
  renderInto('threads',threads=>{
  for (const thread of d.threads || []) {
    const item = document.createElement('div'); item.className = 'thread';
    const label = document.createElement('span'), bar = document.createElement('span'), value = document.createElement('span');
    label.textContent = String(thread.id).padStart(2,'0'); bar.className = 'thread-meter';
    const fill = document.createElement('i');
    fill.style.transform = 'scaleX('+(numeric(thread.load) ? Math.max(0,Math.min(100,thread.load))/100 : 0)+')';
    value.textContent = number(thread.load)+'%'; bar.append(fill);item.append(label,bar,value);threads.append(item);
  }
  if (!threads.children.length) threads.textContent = 'Compteurs indisponibles';
  });const gpu = d.gpu || {};renderInto('gpu-details',details=>{
  row(details,'CORE',number(gpu.clock)+' MHz'); row(details,'MEM CLOCK',number(gpu.memoryClock)+' MHz');
  row(details,'VRAM',number(numeric(gpu.memoryUsed)?gpu.memoryUsed/1024:null,1)+' / '+number(numeric(gpu.memoryTotal)?gpu.memoryTotal/1024:null,1)+' Gio');
  row(details,'THERMAL',number(gpu.temperature,1)+' °C / '+number(gpu.power,1)+' W');
  row(details,'FAN / STATE',number(gpu.fan)+'% / '+(gpu.state || '—'));
  });renderInto('disk-activity',disks=>{
  for (const disk of d.diskActivity || []) {
    const item = document.createElement('div');item.className='io-disk';
    const title = document.createElement('div'), rates = document.createElement('div');
    title.textContent='DISK '+disk.name+' · queue '+number(disk.queue); title.className='dim';
    rates.textContent='R '+number(disk.read,2)+' / W '+number(disk.write,2)+' Mio/s';item.append(title,rates);disks.append(item);
  }
  if (!disks.children.length) disks.textContent='Compteurs indisponibles';
  });renderInto('processes',processes=>{
  for (const process of d.processes || []) {
    const tr = document.createElement('tr');
    for (const value of [process.name+' / '+process.pid,number(process.cpu,1)+'%',number(process.memory)+' Mio']) {
      const td = document.createElement('td');td.textContent=value;tr.append(td);
    }
    processes.append(tr);
  }
  if (!processes.children.length) { const tr=document.createElement('tr'),td=document.createElement('td');td.colSpan=3;td.textContent='Compteurs indisponibles';tr.append(td);processes.append(tr); }
  });
}
window.receiveTelemetry = function(d) { if (!d || !d.timestamp || d.timestamp===lastStamp) return; baseTelemetry(d); renderNerd(d); };
if (lastData) renderNerd(lastData);
