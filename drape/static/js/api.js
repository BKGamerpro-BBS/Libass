const API_BASE = '/api/libaas';

const api = {
  async request(endpoint, options = {}) {
    options.credentials = 'include';
    const response = await fetch(`${API_BASE}${endpoint}`, options);
    if (!response.ok) {
      if (response.status === 401) throw new Error('unauthorized');
      throw new Error(`API Error: ${response.status}`);
    }
    return await response.json();
  },
  checkSession() { return this.request('/auth/session'); },
  login(e, p) { return this.request('/auth/login', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({email:e,password:p})}); },
  register(e, p, g) { return this.request('/auth/register', { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({email:e,password:p,gender:g})}); },
  logout() { return this.request('/auth/logout', {method:'POST'}); },
  getWardrobe() { return this.request('/wardrobe'); },
  addWardrobeItem(files) {
    const fd = new FormData();
    if (files instanceof FileList || Array.isArray(files)) { for(let i=0;i<files.length;i++) fd.append('images',files[i]); } else { fd.append('images',files); }
    return fetch(`${API_BASE}/wardrobe`,{method:'POST',body:fd,credentials:'include'}).then(r=>{if(!r.ok)throw new Error("Upload failed");return r.json();});
  },
  updateWardrobeItem(id, data) { return this.request(`/wardrobe/${id}`,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}); },
  deleteWardrobeItem(id) { return this.request(`/wardrobe/${id}`,{method:'DELETE'}); },
  getSuggestions(w,o,p='casual') { return this.request(`/suggestions?weather=${w}&occasion=${o}&persona=${p}`); },
  sendFeedback(ids,liked) { return this.request('/feedback',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({item_ids:ids,is_liked:liked})}); },
  saveLook(d,r,s,o) { return this.request('/saved_looks',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({outfit_data:d,reasoning:r,season:s,occasion:o})}); },
  getSavedLooks() { return this.request('/saved_looks'); },
  getColorPalette() { return this.request('/color_palette'); },
  rateOutfit(file) {
    const fd = new FormData(); fd.append('image',file);
    return fetch(`${API_BASE}/rate_outfit`,{method:'POST',body:fd,credentials:'include'}).then(r=>{if(!r.ok)throw new Error("Rating failed");return r.json();});
  },
  getRatings() { return this.request('/ratings'); }
};
