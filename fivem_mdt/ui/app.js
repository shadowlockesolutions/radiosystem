const app = document.getElementById('app');
const meta = document.getElementById('meta');
const loginPanel = document.getElementById('loginPanel');
const mainPanels = document.getElementById('mainPanels');
const loginHint = document.getElementById('loginHint');
const policePanel = document.getElementById('policePanel');
const casePanel = document.getElementById('casePanel');
const emsPanel = document.getElementById('emsPanel');
const officerPanel = document.getElementById('officerPanel');
const dispatcherPanel = document.getElementById('dispatcherPanel');
const supervisorPanel = document.getElementById('supervisorPanel');

const dispatchCalls = document.getElementById('dispatchCalls');
const suspectList = document.getElementById('suspectList');
const officerList = document.getElementById('officerList');
const bodycamList = document.getElementById('bodycamList');
const chargeList = document.getElementById('chargeList');
const caseList = document.getElementById('caseList');
const reportList = document.getElementById('reportList');
const evidenceList = document.getElementById('evidenceList');
const unitList = document.getElementById('unitList');
const activeCallList = document.getElementById('activeCallList');
const dispatchMap = document.getElementById('dispatchMap');
const callModal = document.getElementById('callModal');
const callModalTitle = document.getElementById('callModalTitle');
const callModalDetails = document.getElementById('callModalDetails');
const callModalCoords = document.getElementById('callModalCoords');

let dispatcherActive = false;
let bodycamActive = false;
let cachedCallsign = '';
let latestBounds = null;

const post = (action, data = {}) => fetch(`https://${GetParentResourceName()}/${action}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(data)
});

const closeMdtUi = () => {
  app.classList.add('hidden');
  callModal.classList.add('hidden');
  post('close');
};

const closeCallModalUi = () => {
  callModal.classList.add('hidden');
};

const parseName = (charinfo) => {
  try {
    const parsed = typeof charinfo === 'string' ? JSON.parse(charinfo) : (charinfo || {});
    return `${parsed.firstname || ''} ${parsed.lastname || ''}`.trim();
  } catch { return ''; }
};

const renderCards = (el, cards) => { el.innerHTML = cards.join(''); };

const worldToMap = (x, y) => {
  if (!latestBounds) return { x: 0, y: 0 };
  const nx = (x - latestBounds.xMin) / (latestBounds.xMax - latestBounds.xMin);
  const ny = (y - latestBounds.yMin) / (latestBounds.yMax - latestBounds.yMin);
  return {
    x: Math.max(0, Math.min(dispatchMap.width, nx * dispatchMap.width)),
    y: Math.max(0, Math.min(dispatchMap.height, dispatchMap.height - (ny * dispatchMap.height)))
  };
};

const drawDispatchMap = (units = [], calls = []) => {
  const ctx = dispatchMap.getContext('2d');
  ctx.fillStyle = '#0b1220';
  ctx.fillRect(0, 0, dispatchMap.width, dispatchMap.height);

  ctx.strokeStyle = '#1f2937';
  for (let x = 0; x < dispatchMap.width; x += 50) {
    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, dispatchMap.height); ctx.stroke();
  }
  for (let y = 0; y < dispatchMap.height; y += 50) {
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(dispatchMap.width, y); ctx.stroke();
  }

  calls.forEach((c) => {
    if (!c.location) return;
    const p = worldToMap(c.location.x || 0, c.location.y || 0);
    ctx.fillStyle = '#ef4444';
    ctx.beginPath(); ctx.arc(p.x, p.y, 7, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#fecaca';
    ctx.fillText(c.id || 'CALL', p.x + 9, p.y + 4);
  });

  units.forEach((u) => {
    const p = worldToMap(u.x || 0, u.y || 0);
    ctx.fillStyle = (u.job === 'ambulance' || u.job === 'ems') ? '#10b981' : '#3b82f6';
    ctx.fillRect(p.x - 4, p.y - 4, 8, 8);
    ctx.fillStyle = '#bfdbfe';
    ctx.fillText(u.callsign || u.playerName || 'UNIT', p.x + 8, p.y + 3);
  });
};

const renderSuspects = (rows = []) => renderCards(suspectList, rows.map((s) => `<article class="card"><strong>${s.first_name || ''} ${s.last_name || ''} (${s.suspect_cid || ''})</strong><small>Risk: ${s.risk_level || 'N/A'}</small></article>`));
const renderOfficers = (rows = []) => renderCards(officerList, rows.map((o) => `<article class="card"><strong>${parseName(o.charinfo) || 'Unknown Officer'}</strong><small>${o.callsign || 'N/A'} | ${o.rank_title || 'N/A'}</small></article>`));
const renderBodycams = (rows = []) => renderCards(bodycamList, rows.map((c) => `<article class="card"><strong>${c.playerName || 'Unknown'} (${(c.role || '').toUpperCase()})</strong><a href="${c.stream_url}" target="_blank">Open Stream</a></article>`));
const renderCharges = (rows = []) => renderCards(chargeList, rows.map((c) => `<article class="card"><strong>${c.code} - ${c.title}</strong><small>Fine: $${c.fine || 0} | Jail: ${c.jail_months || 0}m</small></article>`));
const renderCases = (rows = []) => renderCards(caseList, rows.map((c) => `<article class="card"><strong>${c.case_number} - ${c.title}</strong><small>${c.case_type} | ${c.status}</small></article>`));
const renderReports = (rows = []) => renderCards(reportList, rows.map((r) => `<article class="card"><strong>#${r.id} ${r.title}</strong><small>Case: ${r.case_id || 'N/A'}</small></article>`));
const renderEvidence = (rows = []) => renderCards(evidenceList, rows.map((e) => `<article class="card"><strong>${e.evidence_number} - ${e.title}</strong><small>Locker: ${e.locker_code || 'digital'}</small></article>`));
const renderUnits = (rows = []) => renderCards(unitList, rows.map((u) => `<article class="card"><strong>${u.callsign || u.playerName}</strong><small>${u.job} | X:${Math.floor(u.x)} Y:${Math.floor(u.y)}</small></article>`));
const openCallCard = (call) => {
  callModalTitle.textContent = `${call.id || 'CALL'} - ${(call.type || 'Unknown').toUpperCase()}`;
  callModalDetails.textContent = call.details || 'No details provided';
  if (call.location) {
    callModalCoords.textContent = `Coords: X ${Math.floor(call.location.x || 0)}, Y ${Math.floor(call.location.y || 0)}, Z ${Math.floor(call.location.z || 0)}`;
  } else {
    callModalCoords.textContent = 'Coords: N/A';
  }
  callModal.classList.remove('hidden');
};

const renderActiveCalls = (rows = []) => renderCards(activeCallList, rows.map((c, idx) => `
  <article class="dispatch-call-card" onclick='openCallCardById(${idx})'>
    <strong>#${c.id}</strong>
    <small>${(c.type || 'call').toUpperCase()}</small>
    <small>${(c.details || '').slice(0, 40)}</small>
    <div class="dispatch-call-actions">
      <button onclick="event.stopPropagation(); resolveCall('${c.id}')">Resolve</button>
      <button onclick="event.stopPropagation(); openCallCardById(${idx})">Open</button>
    </div>
  </article>
`));

let lastRenderedCalls = [];

window.resolveCall = (callId) => post('resolveCall', { callId });
window.openCallCardById = (idx) => {
  const call = lastRenderedCalls[idx];
  if (call) openCallCard(call);
};

const renderAuthenticatedView = (data) => {
  loginPanel.classList.add('hidden');
  mainPanels.classList.remove('hidden');

  cachedCallsign = data.profile?.callsign || '';
  latestBounds = data.mapBounds;
  meta.innerText = `Role: ${data.role.toUpperCase()} | Callsign: ${cachedCallsign || 'N/A'} | Dispatchers Online: ${data.dispatchersOnline}`;

  const police = data.role === 'police';
  const dispatcher = data.role === 'police' || data.role === 'ems';

  policePanel.classList.toggle('hidden', !police);
  casePanel.classList.toggle('hidden', !police);
  officerPanel.classList.toggle('hidden', !police);
  supervisorPanel.classList.toggle('hidden', !data.isSupervisor);
  emsPanel.classList.toggle('hidden', data.role !== 'ems');
  dispatcherPanel.classList.toggle('hidden', !dispatcher);

  renderSuspects(data.suspects || []);
  renderOfficers(data.officers || []);
  renderBodycams(data.bodycams || []);
  renderCharges(data.charges || []);
  renderCases(data.cases || []);
  renderReports(data.reports || []);
  renderEvidence(data.evidence || []);
  renderUnits(data.liveUnits || []);
  lastRenderedCalls = data.activeCalls || [];
  renderActiveCalls(lastRenderedCalls);
  drawDispatchMap(data.liveUnits || [], data.activeCalls || []);
};

const renderLoginView = (data) => {
  mainPanels.classList.add('hidden');
  loginPanel.classList.remove('hidden');
  if (!data.hasAccount) {
    loginHint.textContent = 'No MDT SQL account assigned. Ask a supervisor to create your login.';
  } else {
    loginHint.textContent = 'Enter your MDT SQL login credentials.';
  }
};

const applyBootstrap = (data) => {
  if (data.requiresLogin) renderLoginView(data); else renderAuthenticatedView(data);
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

document.getElementById('close').onclick = () => closeMdtUi();
document.getElementById('refresh').onclick = async () => {
  const response = await post('refresh');
  const data = await response.json();
  if (data.allowed) applyBootstrap(data);
};

document.getElementById('doLogin').onclick = async () => {
  const response = await post('login', { username: document.getElementById('mdtUser').value, password: document.getElementById('mdtPass').value });
  const result = await response.json();
  if (!result.ok) {
    loginHint.textContent = result.message || 'Login failed';
    return;
  }
  document.getElementById('refresh').click();
};

document.getElementById('saveAccount').onclick = () => post('setMdtAccount', {
  citizenid: document.getElementById('accountCid').value,
  username: document.getElementById('accountUser').value,
  password: document.getElementById('accountPass').value
});

document.getElementById('dispatchToggle').onclick = () => { dispatcherActive = !dispatcherActive; post('setDispatchStatus', { active: dispatcherActive }); };
document.getElementById('bodycamToggle').onclick = () => { bodycamActive = !bodycamActive; post('setBodycamStatus', { active: bodycamActive, stream_url: document.getElementById('bodycamUrl').value, callsign: cachedCallsign }); };
document.getElementById('createWarrant').onclick = () => post('createWarrant', { suspect_name: document.getElementById('warrantName').value, suspect_cid: document.getElementById('warrantCid').value, notes: document.getElementById('warrantNotes').value, charges: [] });
document.getElementById('createCaseEMS').onclick = () => post('createEMSCase', { patient_cid: document.getElementById('patientCid').value, severity: document.getElementById('severity').value, summary: document.getElementById('summary').value, injury_type: 'unknown', treatment: 'pending' });
document.getElementById('saveSuspect').onclick = () => post('saveSuspect', { suspect_cid: document.getElementById('suspectCid').value, first_name: document.getElementById('suspectFirstName').value, last_name: document.getElementById('suspectLastName').value, dob: document.getElementById('suspectDob').value, photo_url: document.getElementById('suspectPhoto').value, fingerprint_url: document.getElementById('suspectPrint').value, dna_profile: document.getElementById('suspectDna').value, phone: document.getElementById('suspectPhone').value, address: document.getElementById('suspectAddress').value, parole_status: document.getElementById('suspectParole').value, risk_level: document.getElementById('suspectRisk').value, notes: document.getElementById('suspectNotes').value });
document.getElementById('saveOfficer').onclick = () => post('updateOfficer', { citizenid: document.getElementById('officerCid').value, callsign: document.getElementById('officerCallsign').value, rank_title: document.getElementById('officerRank').value, profile_image_url: document.getElementById('officerPhoto').value, badge_image_url: document.getElementById('officerBadge').value });
document.getElementById('addCharge').onclick = () => post('addCharge', { code: document.getElementById('chargeCode').value, title: document.getElementById('chargeTitle').value, category: document.getElementById('chargeCategory').value, class: document.getElementById('chargeClass').value, fine: document.getElementById('chargeFine').value, jail_months: document.getElementById('chargeJail').value, points: document.getElementById('chargePoints').value, statute: document.getElementById('chargeStatute').value, notes: document.getElementById('chargeNotes').value });
document.getElementById('createCase').onclick = () => {
  const charges = document.getElementById('caseChargeIds').value.split(',').map((id) => id.trim()).filter(Boolean).map((id) => ({ id: Number(id), label: `Charge #${id}`, count: 1 }));
  post('createCase', { title: document.getElementById('caseTitle').value, case_type: document.getElementById('caseType').value, priority: document.getElementById('casePriority').value, suspect_cid: document.getElementById('caseSuspectCid').value, officer_cid: document.getElementById('caseOfficerCid').value, assigned_unit: document.getElementById('caseUnit').value, summary: document.getElementById('caseSummary').value, charges });
};
document.getElementById('createReport').onclick = () => post('createReport', { case_id: document.getElementById('reportCaseId').value, report_type: document.getElementById('reportType').value, title: document.getElementById('reportTitle').value, narrative: document.getElementById('reportNarrative').value, findings: document.getElementById('reportFindings').value, recommendations: document.getElementById('reportRecommendations').value });
document.getElementById('addEvidence').onclick = () => post('addEvidence', { case_id: document.getElementById('evidenceCaseId').value, report_id: document.getElementById('evidenceReportId').value, evidence_type: document.getElementById('evidenceType').value, title: document.getElementById('evidenceTitle').value, description: document.getElementById('evidenceDescription').value, file_url: document.getElementById('evidenceFileUrl').value, thumb_url: document.getElementById('evidenceThumbUrl').value, metadata_json: document.getElementById('evidenceMeta').value, is_physical: document.getElementById('isPhysicalEvidence').checked, locker_code: document.getElementById('evidenceLocker').value, shelf_slot: document.getElementById('evidenceShelf').value, seal_number: document.getElementById('evidenceSeal').value, weight_grams: document.getElementById('evidenceWeight').value, condition_note: document.getElementById('evidenceCondition').value });

document.getElementById('closeCallModal').onclick = () => closeCallModalUi();


callModal.addEventListener('click', (event) => {
  if (event.target === callModal) closeCallModalUi();
});


document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape') return;
  if (!callModal.classList.contains('hidden')) {
    closeCallModalUi();
    return;
  }
  if (!app.classList.contains('hidden')) closeMdtUi();
});
