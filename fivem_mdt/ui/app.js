const app = document.getElementById('app');
const meta = document.getElementById('meta');
const policePanel = document.getElementById('policePanel');
const emsPanel = document.getElementById('emsPanel');
const dispatchCalls = document.getElementById('dispatchCalls');

let dispatcherActive = false;

const post = (action, data = {}) => fetch(`https://${GetParentResourceName()}/${action}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data)
});

window.addEventListener('message', (event) => {
  const msg = event.data;

  if (msg.action === 'open') {
    app.classList.remove('hidden');
    const { role, profile, dispatchersOnline } = msg.payload;
    meta.innerText = `Role: ${role.toUpperCase()} | Callsign: ${profile?.callsign || 'N/A'} | Dispatchers Online: ${dispatchersOnline}`;
    policePanel.classList.toggle('hidden', role !== 'police');
    emsPanel.classList.toggle('hidden', role !== 'ems');
  }

  if (msg.action === 'dispatchCall') {
    const li = document.createElement('li');
    li.textContent = `${msg.payload.type} - ${msg.payload.details || ''}`;
    dispatchCalls.prepend(li);
  }

  if (msg.action === 'dispatcherPrompt') {
    const li = document.createElement('li');
    li.textContent = `[DISPATCH QUEUE] ${msg.payload.type} - ${msg.payload.details || ''}`;
    dispatchCalls.prepend(li);
  }
});

document.getElementById('close').onclick = () => {
  app.classList.add('hidden');
  post('close');
};

document.getElementById('dispatchToggle').onclick = () => {
  dispatcherActive = !dispatcherActive;
  post('setDispatchStatus', { active: dispatcherActive });
};

document.getElementById('createWarrant').onclick = () => {
  post('createWarrant', {
    suspect_name: document.getElementById('warrantName').value,
    suspect_cid: document.getElementById('warrantCid').value,
    notes: document.getElementById('warrantNotes').value,
    charges: []
  });
};

document.getElementById('createCase').onclick = () => {
  post('createEMSCase', {
    patient_cid: document.getElementById('patientCid').value,
    severity: document.getElementById('severity').value,
    summary: document.getElementById('summary').value,
    injury_type: 'unknown',
    treatment: 'pending'
  });
};
