"use strict";Object.defineProperties(exports,{__esModule:{value:!0},[Symbol.toStringTag]:{value:"Module"}});const n=require("solid-js/web"),l=require("effect"),c=require("solid-js"),i=require("@opencode/plugin/gui");var g=n.template("<div class=threads-note-wrap><textarea class=threads-note>");const h=i.Plugin.define({i18n:{en:{"button.label":"Thread Notes","panel.title":"Thread Notes","note.placeholder":"Write a note for this thread…"}},stores:{notes:i.Store.global(l.Schema.Struct({bySession:l.Schema.Record(l.Schema.String,l.Schema.String)}),{bySession:{}})}}),p=i.Plugin.define({...h,setup(e){const o=e.ui,d={id:"thread",get title(){return e.t("panel.title")}};e.add(i.Style,`.threads-note-wrap {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  padding: 8px;
}
.threads-note {
  flex: 1;
  width: 100%;
  resize: none;
  border: none;
  outline: none;
  background: transparent;
  color: inherit;
  font: inherit;
  padding: 0;
}`),c.createComputed(()=>{for(const t of Object.keys(e.stores.notes.value.bySession)){const[a,s]=t.split(`
`),r=e.servers.get(a)?.data;(!r||r.session.missing(s))&&e.stores.notes.update(u=>{delete u.bySession[t]})}}),e.add(i.Panel,{id:"thread",region:"side",list:t=>t.open.includes("thread")?[d]:[],render:t=>n.createComponent(b,{session:()=>t.session})}),e.add(i.Slot,{at:"session.header",render:t=>n.createComponent(o.Tooltip,{get value(){return e.t("button.label")},placement:"bottom",get children(){return n.createComponent(o.IconButton,{icon:"edit",get label(){return e.t("button.label")},get pressed(){return e.layout.state(`${e.id}:thread`,t.session)==="visible"},onClick:()=>e.layout.toggle(`${e.id}:thread`,t.session)})}})})}});function b(e){const o=i.usePlugin(),d=()=>o.stores.notes.value.bySession[e.session().key]??"",t=a=>{const s=e.session(),r=o.servers.get(s.server.id)?.data;!r||r.session.missing(s.id)||o.stores.notes.update(u=>{u.bySession[s.key]=a})};return(()=>{var a=g(),s=a.firstChild;return s.$$input=r=>t(r.currentTarget.value),n.effect(()=>n.setAttribute(s,"placeholder",o.t("note.placeholder"))),n.effect(()=>s.value=d()),a})()}n.delegateEvents(["input"]);exports.default=p;
