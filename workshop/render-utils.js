'use strict';
// Preserve live nodes (and their CSS transitions); only patch changed content.
function reconcile(parent, fresh) {
  const nodes=Array.from(fresh.childNodes);
  for(let i=0;i<nodes.length;i++){
    const next=nodes[i],current=parent.childNodes[i];
    if(!current){parent.append(next);continue}
    if(current.nodeType!==next.nodeType||current.nodeName!==next.nodeName){current.replaceWith(next);continue}
    if(next.nodeType===Node.TEXT_NODE){if(current.nodeValue!==next.nodeValue)current.nodeValue=next.nodeValue;continue}
    for(const attr of Array.from(current.attributes))if(!next.hasAttribute(attr.name))current.removeAttribute(attr.name);
    for(const attr of Array.from(next.attributes))if(current.getAttribute(attr.name)!==attr.value)current.setAttribute(attr.name,attr.value);
    reconcile(current,next);
  }
  while(parent.childNodes.length>nodes.length)parent.lastChild.remove();
}
function renderInto(id,build){const fragment=document.createElement('div');build(fragment);reconcile(document.getElementById(id),fragment)}
