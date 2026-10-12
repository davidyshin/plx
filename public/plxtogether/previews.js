(() => {
  const root = document.querySelector('#previews');
  if (!root) return;
  const tabs = [...root.querySelectorAll('[data-preview]')];
  tabs.forEach(button => button.addEventListener('click', () => {
    tabs.forEach(tab => tab.setAttribute('aria-pressed', String(tab === button)));
    root.querySelectorAll('.preview-panel').forEach(panel => panel.hidden = panel.id !== button.dataset.preview);
  }));
  const stops = [
    {name:'Shared quest hub',point:[.28,.30],tasks:[['PICK UP','Crossroads supply run','Accept the quest from the quest giver.','You, Throk'],['PICK UP','A shared hunt','Accept the quest before heading out.','You, Mira, Throk']]},
    {name:'Crossroads supply run',point:[.43,.40],tasks:[['COMPLETE OBJECTIVE','Gather supplies','Gather supplies from the camp.','You, Throk']]},
    {name:'A shared hunt',point:[.47,.55],tasks:[['COMPLETE OBJECTIVE','Clear the hunting grounds','Finish the remaining hunt objective.','You, Mira, Throk']]},
    {name:'Crossroads supply run',point:[.55,.50],tasks:[['COMPLETE OBJECTIVE','Recover the missing crate','Find the crate at the camp.','You, Mira, Throk']]},
    {name:'Return to the shared hub',point:[.28,.30],tasks:[['TURN IN','Crossroads supply run','Hand in the completed quest.','You, Mira, Throk'],['TURN IN','A shared hunt','Hand in the completed quest.','You, Mira, Throk']]}
  ];
  let step = 0, origin = [.18,.20];
  const get = id => root.querySelector('#'+id);
  function renderArrow() {
    const target = stops[Math.min(step,stops.length-1)].point;
    const east=(target[0]-origin[0])*8000,north=(origin[1]-target[1])*6000;
    const heading=Number(get('preview-heading').value);
    const angle=Math.atan2(east,north)*180/Math.PI-heading;
    get('gps-pointer').setAttribute('transform',`rotate(${angle} 80 80)`);
    get('preview-distance').textContent=step===stops.length?'Route complete':Math.round(Math.hypot(east,north))+' yd';
    get('heading-label').textContent=`Facing ${heading}° · ${['North','Northeast','East','Southeast','South','Southwest','West','Northwest'][Math.round(heading/45)%8]}`;
  }
  function render() {
    const done=step===stops.length,s=stops[Math.min(step,stops.length-1)];
    get('preview-step-number').textContent=done?'✓':String(step+1).padStart(2,'0');
    get('preview-stop-name').textContent=done?'Route complete':s.name;
    get('preview-stop-meta').textContent=done?'All simulated tasks finished':`NEXT STOP · ${s.tasks.length} substep${s.tasks.length===1?'':'s'} · ${(s.point[0]*100).toFixed(1)}, ${(s.point[1]*100).toFixed(1)}`;
    const container=get('preview-substeps'); container.replaceChildren();
    if(!done)s.tasks.forEach((task,i)=>{
      const row=document.createElement('div');row.className='substep';
      const number=document.createElement('span');number.className='substep-index';number.textContent=`${step+1}.${i+1}`;
      const body=document.createElement('div'),action=document.createElement('strong'),instruction=document.createElement('p'),members=document.createElement('small');
      action.textContent=task[0]+' · '+task[1];instruction.textContent=task[2];members.textContent='Needed by: '+task[3];
      body.append(action,instruction,members);row.append(number,body);container.append(row);
    });
    get('preview-progress').textContent=done?'Five stops completed':`Illustration · stop ${step+1} of ${stops.length}`;
    get('preview-next').disabled=done;
    root.querySelectorAll('[data-map-stop]').forEach((marker,i)=>{
      const current=i===step; marker.querySelector('circle').setAttribute('fill',current?'#efcb87':i<step?'#354039':'#15231b');
      marker.querySelector('circle').setAttribute('stroke',current?'#efcb87':'#9cc7ac');
      marker.querySelector('text').setAttribute('fill',current?'#20251e':'#e1e9df');
    });
    renderArrow();
  }
  get('preview-next').addEventListener('click',()=>{if(step<stops.length){origin=stops[step].point;step++;render();}});
  get('preview-reset').addEventListener('click',()=>{step=0;origin=[.18,.20];render();});
  get('preview-heading').addEventListener('input',renderArrow);
  const people=[['You',12,9000],['Mira',15,13000],['Throk',17,17000]];
  function renderXP(){
    const old=get('preview-quest').value==='old';
    root.querySelectorAll('.xp-person').forEach((row,i)=>{
      const retention=old?[.8,.2,.1][i]:1,xp=Math.floor((old?450:950)*retention);
      row.querySelector('strong').textContent=xp+' XP';
      row.querySelector('small').textContent=`Level ${people[i][1]} · ${Math.round(retention*100)}% XP retained · ${(xp/people[i][2]*100).toFixed(1)}% of a level`;
      row.querySelector('.xp-bar span').style.width=retention*100+'%';
    });
  }
  get('preview-quest').addEventListener('change',renderXP);renderXP();render();
})();
