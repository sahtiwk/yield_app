import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';

// Local verification only: admin credentials stay in this process and are used
// solely to remove the disposable users created by this test.
const status = JSON.parse(execFileSync('cmd.exe', ['/d','/s','/c','npx.cmd supabase status -o json'], { encoding:'utf8', stdio:['ignore','pipe','pipe'] }));
const url = new URL(status.API_URL);
if (!['127.0.0.1','localhost'].includes(url.hostname)) throw new Error('Smoke test only supports local Supabase');
const key = status.PUBLISHABLE_KEY || status.ANON_KEY;
const users = [];
async function request(path, {token, method = 'GET', body, admin = false} = {}) {
  const response = await fetch(new URL(path,url), { method,
    headers: {apikey: admin ? status.SERVICE_ROLE_KEY : key, ...(token ? {Authorization:`Bearer ${token}`} : {}), 'Content-Type':'application/json'},
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  if (!response.ok) throw new Error(`Request ${path} failed: ${response.status}`);
  return data;
}
try {
  const crops = await request('/rest/v1/crop_configs?select=id&limit=1');
  if (!crops.length) throw new Error('Crop reference read failed');
  for (let index = 0; index < 2; index++) {
    const identity = await request('/auth/v1/signup', {method:'POST', body:{email:`smoke-${randomUUID()}@example.test`,password:`${randomUUID()}Aa1!`}});
    users.push(identity);
    if (!identity.access_token || !identity.user?.id) throw new Error('Local email sign-up did not return a session');
  }
  const token = users[0].access_token;
  const profile = await request('/rest/v1/profiles?select=id,is_onboarded', {token});
  if (profile.length !== 1 || profile[0].is_onboarded !== false) throw new Error('Profile trigger or RLS failed');
  await request(`/rest/v1/profiles?id=eq.${users[0].user.id}`,{token,method:'PATCH',body:{language_preference:'Telugu',is_onboarded:true}});
  const caseId = `smoke-${randomUUID()}`;
  await request('/rest/v1/rpc/save_harvest_case',{token,method:'POST',body:{payload:{
    id:caseId,crop_id:'tomato',quantity_kg:100,location_label:'Test village',harvest_status:'Harvested',
    harvested_at:new Date().toISOString(),urgency:'Must sell today',farmer_condition:'Ready',current_plan:'Test market',
    constraints:[{type:'must_sell_by',value:'Must sell today',is_hard:true}],
  }}});
  const own = await request(`/rest/v1/harvest_cases?id=eq.${caseId}&select=id`,{token});
  const other = await request(`/rest/v1/harvest_cases?id=eq.${caseId}&select=id`,{token:users[1].access_token});
  if (own.length !== 1 || other.length !== 0) throw new Error('Case ownership failed');
  const result = await request('/functions/v1/context_orchestrator',{token,method:'POST',body:{case_id:caseId}});
  if (result.status !== 'unavailable' || result.code !== 'coordinates_required') throw new Error('Expected an explicit missing-coordinate response');
  const rejected = await fetch(new URL('/functions/v1/context_orchestrator',url), {method:'POST',headers:{apikey:key,'Content-Type':'application/json'},body:JSON.stringify({case_id:caseId})});
  if (rejected.status !== 401) throw new Error('Function accepted an unauthenticated request');
  console.log('PASS: public read, profile creation/onboarding, transactional case save, user isolation, authenticated function and unauthenticated rejection.');
} finally {
  for (const identity of users) {
    if (identity.user?.id) await request(`/auth/v1/admin/users/${identity.user.id}`,{method:'DELETE',token:status.SERVICE_ROLE_KEY,admin:true});
  }
}
