document.querySelectorAll('[data-confirm]').forEach(button => button.addEventListener('click', event => {if (!confirm(button.dataset.confirm)) event.preventDefault();}));
const form = document.querySelector('#booking-form');
// Parseo explícito: nunca delegar dd/mm/aaaa a Date.parse (puede asumir mes/día).
const parseDayMonthYear = value => {
 const match = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(value);
 if (!match) return null;
 const [, day, month, year] = match.map(Number);
 const date = new Date(0);
 date.setUTCFullYear(year, month - 1, day);
 date.setUTCHours(0, 0, 0, 0);
 return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day ? date.getTime() : null;
};
if (form) {
 const room=document.querySelector('#room'), start=document.querySelector('#entrada'), end=document.querySelector('#salida'), people=document.querySelector('#personas');
 const money=n=>new Intl.NumberFormat('es-PE',{style:'currency',currency:'PEN'}).format(n);
 const update=()=>{
  const option=room.selectedOptions[0], rate=Number(option.dataset.rate||0);
  const startDate=parseDayMonthYear(start.value), endDate=parseDayMonthYear(end.value);
  const nights=startDate!==null&&endDate!==null?Math.round((endDate-startDate)/86400000):0;
  start.setCustomValidity(start.value&&startDate===null?'Ingrese una fecha válida: dd/mm/aaaa.':'');
  const capacity=Number(option.dataset.capacity||10);people.max=capacity;
  people.setCustomValidity(Number(people.value)>capacity?'La habitación admite hasta '+capacity+' huéspedes.':'');
  end.setCustomValidity(end.value&&endDate===null?'Ingrese una fecha válida: dd/mm/aaaa.':startDate!==null&&endDate!==null&&(nights<1||nights>365)?'La estancia debe tener entre 1 y 365 noches.':'');
  document.querySelector('#summary-room').textContent=room.value?option.textContent.split(' · ').slice(0,2).join(' · '):'Selecciona una habitación';
  document.querySelector('#summary-rate').textContent=money(rate);
  document.querySelector('#summary-nights').textContent=nights>0?nights:'—';
  document.querySelector('#summary-people').textContent=people.value;
  document.querySelector('#summary-total').textContent=money(rate*Math.max(0,nights));
 };
 form.addEventListener('input',update);update();
}
