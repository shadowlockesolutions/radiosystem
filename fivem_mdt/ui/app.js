const app = document.getElementById('app');
const meta = document.getElementById('meta');
const policePanel = document.getElementById('policePanel');
const emsPanel = document.getElementById('emsPanel');
const officerPanel = document.getElementById('officerPanel');
const dispatchCalls = document.getElementById('dispatchCalls');
const suspectList = document.getElementById('suspectList');
const officerList = document.getElementById('officerList');
const bodycamList = document.getElementById('bodycamList');

let dispatcherActive = false;
let bodycamActive = false;
let currentRole = null;
let cachedCallsign = '';

const post = (action, data = {}) => fetch(`https://${GetParentResourceName()}/${action}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data)
});

const parseName = (charinfo) => {
  try {
    const parsed = typeof charinfo === 'string' ? JSON.parse(charinfo) : (charinfo || {});
    return `${parsed.firstname || ''} ${parsed.lastname || ''}`.trim();
  } catch {
    return '';
  }
};

const renderSuspects = (suspects = []) => {
  suspectList.innerHTML = suspects.map((s) => `
    <article class="card">
      <div class="row">
        <img src="${s.photo_url || ''}" alt="photo" onerror="this.style.display='none'" />
        <img src="${s.fingerprint_url || ''}" alt="fingerprint" onerror="this.style.display='none'" />
      </div>
      <strong>${s.first_name || ''} ${s.last_name || ''} (${s.suspect_cid || ''})</strong>
      <small>DOB: ${s.dob || 'N/A'} | DNA: ${s.dna_profile || 'N/A'} | Risk: ${s.risk_level || 'N/A'}</small>
      <small>Parole: ${s.parole_status || 'N/A'} | Phone: ${s.phone || 'N/A'}</small>
      <p>${s.notes || ''}</p>
    </article>
  `).join('');
};

const renderOfficers = (officers = []) => {
  officerList.innerHTML = officers.map((o) => `
    <article class="card">
      <div class="row">
        <img src="${o.profile_image_url || ''}" alt="officer" onerror="this.style.display='none'" />
        <img src="${o.badge_image_url || ''}" alt="badge" onerror="this.style.display='none'" />
      </div>
      <strong>${parseName(o.charinfo) || 'Unknown Officer'}</strong>
      <small>CID: ${o.citizenid}</small>
      <small>Callsign: ${o.callsign || 'N/A'} | Rank: ${o.rank_title || 'N/A'}</small>
    </article>
  `).join('');
};

const renderBodycams = (cams = []) => {
  bodycamList.innerHTML = cams.map((c) => `
    <article class="card">
      <strong>${c.playerName || 'Unknown'} (${(c.role || '').toUpperCase()})</strong>
      <small>Callsign: ${c.callsign || 'N/A'} | CID: ${c.citizenid || 'N/A'}</small>
      <a href="${c.stream_url}" target="_blank">Open Stream</a>
    </article>
  `).join('');
};

const applyBootstrap = (data) => {
  currentRole = data.role;
  cachedCallsign = data.profile?.callsign || '';
  meta.innerText = `Role: ${data.role.toUpperCase()} | Callsign: ${cachedCallsign || 'N/A'} | Dispatchers Online: ${data.dispatchersOnline}`;
  policePanel.classList.toggle('hidden', data.role !== 'police');
  officerPanel.classList.toggle('hidden', data.role !== 'police');
  emsPanel.classList.toggle('hidden', data.role !== 'ems');

  renderSuspects(data.suspects || []);
  renderOfficers(data.officers || []);
  renderBodycams(data.bodycams || []);
};

window.addEventListener('message', (event) => {
  const msg = event.data;
  if (msg.action === 'open') {
    app.classList.remove('hidden');
    applyBootstrap(msg.payload);
  }

  if (msg.action === 'dispatchCall' || msg.action === 'dispatcherPrompt') {
    const li = document.createElement('li');
    li.textContent = `${msg.payload.type} - ${msg.payload.details || ''}`;
    dispatchCalls.prepend(li);
  }
});

document.getElementById('close').onclick = () => {
  app.classList.add('hidden');
  post('close');
};

document.getElementById('refresh').onclick = async () => {
  const response = await post('refresh');
  const data = await response.json();
  if (data.allowed) applyBootstrap(data);
};

document.getElementById('dispatchToggle').onclick = () => {
  dispatcherActive = !dispatcherActive;
  post('setDispatchStatus', { active: dispatcherActive });
};

document.getElementById('bodycamToggle').onclick = () => {
  bodycamActive = !bodycamActive;
  const streamUrl = document.getElementById('bodycamUrl').value;
  post('setBodycamStatus', { active: bodycamActive, stream_url: streamUrl, callsign: cachedCallsign });
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

document.getElementById('saveSuspect').onclick = () => {
  post('saveSuspect', {
    suspect_cid: document.getElementById('suspectCid').value,
    first_name: document.getElementById('suspectFirstName').value,
    last_name: document.getElementById('suspectLastName').value,
    dob: document.getElementById('suspectDob').value,
    photo_url: document.getElementById('suspectPhoto').value,
    fingerprint_url: document.getElementById('suspectPrint').value,
    dna_profile: document.getElementById('suspectDna').value,
    phone: document.getElementById('suspectPhone').value,
    address: document.getElementById('suspectAddress').value,
    parole_status: document.getElementById('suspectParole').value,
    risk_level: document.getElementById('suspectRisk').value,
    notes: document.getElementById('suspectNotes').value
  });
};

document.getElementById('saveOfficer').onclick = () => {
  post('updateOfficer', {
    citizenid: document.getElementById('officerCid').value,
    callsign: document.getElementById('officerCallsign').value,
    rank_title: document.getElementById('officerRank').value,
    profile_image_url: document.getElementById('officerPhoto').value,
    badge_image_url: document.getElementById('officerBadge').value
  });
};
