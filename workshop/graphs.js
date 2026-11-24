'use strict';
// Short, capped transitions only while a new sample is arriving. No idle render loop.
const graphTransitions=new Map();
let graphFrame=0,lastGraphFrame=0,graphFps=30;
let graphColor=getComputedStyle(document.documentElement).getPropertyValue('--accent').trim();

graph=function(key,value){
  const history=histories[key],before=history.slice();
  history.push(numeric(value)?value:null);if(history.length>75)history.shift();
  if(!document.body.classList.contains('no-smoothing')&&!paused){graphTransitions.set(key,{before,start:performance.now()});if(!graphFrame)graphFrame=requestAnimationFrame(animateGraphs)}
  else draw(key);
};
draw=function(key){
  const canvas=$(key+'-chart'),ctx=canvas.getContext('2d'),history=histories[key],transition=graphTransitions.get(key);
  const progress=transition?Math.min(1,(performance.now()-transition.start)/650):1;
  const ease=1-Math.pow(1-progress,3);
  ctx.clearRect(0,0,canvas.width,canvas.height);ctx.strokeStyle='#252c28';ctx.lineWidth=1;
  ctx.beginPath();for(let y=20;y<82;y+=20){ctx.moveTo(0,y);ctx.lineTo(480,y)}ctx.stroke();
  ctx.strokeStyle=graphColor;ctx.lineWidth=2;ctx.beginPath();let started=false;
  history.forEach((value,i)=>{
    if(value===null){started=false;return}
    const previous=transition?.before[Math.min(i,transition.before.length-1)];
    const displayed=numeric(previous)?previous+(value-previous)*ease:value;
    const x=i*480/74,y=80-Math.min(100,Math.max(0,displayed))*.76;
    if(!started){ctx.moveTo(x,y);started=true}else ctx.lineTo(x,y);
  });ctx.stroke();if(progress>=1)graphTransitions.delete(key);
};
function animateGraphs(now){
  graphFrame=0;if(paused){graphTransitions.clear();return}
  if(now-lastGraphFrame>=1000/graphFps){lastGraphFrame=now;for(const key of graphTransitions.keys())draw(key)}
  if(graphTransitions.size)graphFrame=requestAnimationFrame(animateGraphs);
}
const propertiesListener=window.wallpaperPropertyListener.applyUserProperties;
window.wallpaperPropertyListener.applyUserProperties=function(p){propertiesListener(p);if(p.smooth)document.body.classList.toggle('no-smoothing',!p.smooth.value);if(p.accent){graphColor=getComputedStyle(document.documentElement).getPropertyValue('--accent').trim();Object.keys(histories).forEach(draw)}};
window.wallpaperPropertyListener.applyGeneralProperties=function(p){if(numeric(p.fps)&&p.fps>0)graphFps=Math.max(1,Math.min(30,p.fps))};
const pauseListener=window.wallpaperPropertyListener.setPaused;
window.wallpaperPropertyListener.setPaused=function(value){pauseListener(value);if(value){cancelAnimationFrame(graphFrame);graphFrame=0;graphTransitions.clear()}else Object.keys(histories).forEach(draw)};
