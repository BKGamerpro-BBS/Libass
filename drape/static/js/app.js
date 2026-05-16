const app = {
  isAuthenticated: false,
  persona: 'casual',
  currentWeather: 'summer',
  userEmail: '',
  gender: 'unspecified',
  tempUnit: 'f',
  weatherData: null,
  currentRatingFile: null,

  navigate(screenId) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(screenId).classList.add('active');
    document.querySelectorAll('.nav-tab').forEach(n => n.classList.remove('active'));
    const nav = document.querySelector(`.nav-tab[data-target="${screenId}"]`);
    if(nav) nav.classList.add('active');
    const filters = document.getElementById('outfit-filters');
    if(screenId === 'screen-outfit') { filters.style.display = 'flex'; this.loadSuggestions(); }
    else { filters.style.display = 'none'; }
    if(screenId === 'screen-wardrobe') this.loadWardrobe();
    if(screenId === 'screen-home') this.fetchWeather();
    if(screenId === 'screen-camera') this.loadPastRatings();
  },

  toggleAuthModal() {
    if (this.isAuthenticated) {
      document.getElementById('profile-email-text').textContent = this.userEmail;
      document.getElementById('profile-gender-text').textContent = this.gender;
      document.getElementById('profile-avatar').src = `https://ui-avatars.com/api/?name=${this.userEmail}&background=2C5F2D&color=fff&rounded=true&size=128`;
      const m = document.getElementById('profile-modal');
      m.style.display = m.style.display === 'flex' ? 'none' : 'flex';
    } else {
      const m = document.getElementById('auth-modal');
      m.style.display = m.style.display === 'flex' ? 'none' : 'flex';
    }
  },

  async checkAuth() {
    try {
      const s = await api.checkSession();
      this.isAuthenticated = true;
      this.gender = s.gender || 'unspecified';
      this.userEmail = s.email;
      document.getElementById('auth-status').textContent = s.email;
      document.getElementById('auth-modal').style.display = 'none';
      document.getElementById('profile-modal').style.display = 'none';
      document.getElementById('app-container').style.display = 'block';
      document.querySelector('.libaas-nav').style.display = 'flex';
      const d = document.getElementById('option-dress');
      if(d) d.style.display = this.gender === 'male' ? 'none' : 'block';
      this.fetchWeather();
    } catch(e) {
      this.isAuthenticated = false;
      document.getElementById('auth-status').textContent = 'Login / Register';
      document.getElementById('auth-modal').style.display = 'flex';
      document.getElementById('app-container').style.display = 'none';
      document.querySelector('.libaas-nav').style.display = 'none';
    }
  },

  async login() {
    const e = document.getElementById('auth-email').value;
    const p = document.getElementById('auth-pass').value;
    try { await api.login(e, p); await this.checkAuth(); } catch(err) { alert("Login failed"); }
  },

  async register() {
    const e = document.getElementById('auth-email').value;
    const p = document.getElementById('auth-pass').value;
    const g = document.getElementById('auth-gender').value;
    if(g === 'unspecified') { alert("Please select a gender"); return; }
    try { await api.register(e, p, g); await this.checkAuth(); } catch(err) { alert("Registration failed"); }
  },

  async logout() {
    try { await api.logout(); this.isAuthenticated = false; this.userEmail = ''; document.getElementById('profile-modal').style.display = 'none'; await this.checkAuth(); } catch(e) {}
  },

  async loadWardrobe() {
    if(!this.isAuthenticated) return;
    const grid = document.getElementById('wardrobe-grid');
    grid.innerHTML = '<div class="spinner" style="margin:20px auto;"></div>';
    try {
      const items = await api.getWardrobe();
      if(!items.length) { grid.innerHTML = '<p style="color:var(--text-secondary);text-align:center;">Upload clothing items to get started!</p>'; return; }
      grid.innerHTML = items.map(item => {
        const season = item.season || 'all';
        const seasonEmoji = {summer:'☀️',winter:'❄️',spring:'🌸',rainy:'🌧️',all:'🔄'}[season] || '🔄';
        return `
        <div class="card" style="position:relative;padding:12px;cursor:pointer;" onclick="app.openEditModal(${JSON.stringify(item).replace(/"/g,'&quot;')})">
          <button class="btn-danger" style="position:absolute;top:8px;right:8px;z-index:10;" onclick="event.stopPropagation(); app.deleteItem('${item.id}')">🗑️</button>
          <img src="${item.image_path}" style="width:100%;height:130px;object-fit:contain;border-radius:var(--radius-md);background:var(--bg-surface-dim);">
          <p style="margin:10px 0 2px;font-weight:600;font-size:14px;">${item.name}</p>
          <p style="margin:0;font-size:11px;color:var(--text-secondary);">${item.category} • ${item.specific_type || 'Unknown'} • ${item.fit}</p>
          <span class="pill pill-green" style="margin-top:6px;font-size:10px;">${seasonEmoji} ${season.charAt(0).toUpperCase()+season.slice(1)}</span>
        </div>
      `}).join('');
    } catch(e) { grid.innerHTML = 'Error loading wardrobe'; }
    this.loadColorPalette();
  },

  async loadColorPalette() {
    const zone = document.getElementById('color-palette-zone');
    const content = document.getElementById('color-palette-content');
    zone.style.display = 'block';
    try {
      const data = await api.getColorPalette();
      if(!data.dominant || !data.dominant.length) { content.innerHTML = "Upload items to see your color analysis."; return; }
      let html = `<p style="margin:0 0 8px;"><strong>Dominant Colors:</strong> ${data.dominant.map(d=>`<span class="pill pill-green" style="margin-right:4px;">${d.color} (${d.count})</span>`).join('')}</p>`;
      if(data.clashing.length > 0) html += `<p style="margin:0;color:var(--color-danger);">⚠️ ${data.clashing.join(' ')}</p>`;
      else html += `<p style="margin:0;color:var(--color-success);">✅ Your wardrobe colors harmonize beautifully!</p>`;
      content.innerHTML = html;
    } catch(e) { content.innerHTML = 'Failed to analyze colors.'; }
  },

  async deleteItem(id) {
    if(confirm("Delete this item?")) { try { await api.deleteWardrobeItem(id); this.loadWardrobe(); } catch(e) { alert("Failed to delete."); } }
  },

  async loadSuggestions() {
    if(!this.isAuthenticated) return;
    const grid = document.getElementById('suggestions-grid');
    grid.innerHTML = '<div class="spinner" style="margin:20px auto;"></div>';
    const w = document.getElementById('filter-weather').value;
    const o = document.getElementById('filter-occasion').value;
    try {
      const items = await api.getSuggestions(w, o, this.persona);
      if(!items || !items.length) { grid.innerHTML = `<p style="color:var(--text-secondary);">No outfits for ${o} in ${w}. Upload more items!</p>`; return; }
      grid.innerHTML = items.map(outfit => `
        <div class="card" style="border-left:4px solid var(--accent-primary);">
          <div style="display:flex;gap:8px;overflow-x:auto;">
            ${outfit.items.map(i => `<img src="${i.image_path}" title="${i.name}" style="width:60px;height:60px;object-fit:contain;border-radius:var(--radius-md);background:var(--bg-surface-dim);border:1px solid var(--border-subtle);">`).join('')}
          </div>
          <div style="margin-top:12px;display:flex;align-items:center;gap:8px;">
            <span class="pill pill-coral">${outfit.body_shape_score}/10</span>
            <span style="font-size:13px;color:var(--text-secondary);font-style:italic;">${outfit.reasoning}</span>
          </div>
          <div style="margin-top:12px;display:flex;gap:8px;">
            <button class="btn-secondary" style="flex:1;padding:8px;font-size:12px;" onclick="app.sendFeedback(this,'${outfit.items.map(i=>i.id).join(',')}',1)">✅ Like</button>
            <button class="btn-danger" style="flex:1;padding:8px;font-size:12px;" onclick="app.sendFeedback(this,'${outfit.items.map(i=>i.id).join(',')}',0)">❌ Dislike</button>
            <button class="btn-ghost" style="flex:1;padding:8px;font-size:12px;" onclick="app.saveLook(this,'${outfit.items.map(i=>i.id).join(',')}','${outfit.reasoning.replace(/'/g,"\\'")}')">💾 Save</button>
          </div>
        </div>
      `).join('');
      this.loadSavedLooks();
    } catch(e) { grid.innerHTML = 'Error loading outfits'; }
  },

  async saveLook(btn, ids, reasoning) {
    btn.disabled = true; btn.textContent = "Saving...";
    try {
      const w = document.getElementById('filter-weather').value;
      const o = document.getElementById('filter-occasion').value;
      await api.saveLook(ids, reasoning, w, o);
      btn.textContent = "Saved!"; this.loadSavedLooks();
    } catch(e) { btn.disabled = false; btn.textContent = "Failed"; }
  },

  async loadSavedLooks() {
    const grid = document.getElementById('saved-looks-grid');
    if(!grid) return;
    try {
      const looks = await api.getSavedLooks();
      if(!looks || !looks.length) { grid.innerHTML = '<p style="font-size:14px;color:var(--text-secondary);">No saved looks yet.</p>'; return; }
      grid.innerHTML = looks.map(l => `
        <div class="card">
          <p style="font-size:12px;color:var(--text-secondary);margin-bottom:8px;text-transform:capitalize;">${l.season} • ${l.occasion}</p>
          <p style="font-size:14px;margin-top:0;">${l.reasoning}</p>
        </div>
      `).join('');
    } catch(e) { grid.innerHTML = 'Error loading saved looks'; }
  },

  async sendFeedback(btn, ids, liked) {
    btn.parentNode.innerHTML = `<span class="pill pill-green">Feedback saved to AI!</span>`;
    try { await api.sendFeedback(ids.split(','), liked); } catch(e) {}
  },

  setPersona(p) {
    this.persona = p;
    const c = document.getElementById('btn-persona-casual');
    const f = document.getElementById('btn-persona-fashion');
    if(p === 'casual') { c.style.background='var(--accent-primary)'; c.style.color='#fff'; f.style.background='transparent'; f.style.color='var(--text-primary)'; }
    else { f.style.background='var(--accent-primary)'; f.style.color='#fff'; c.style.background='transparent'; c.style.color='var(--text-primary)'; }
    this.loadDailySuggestion();
    if(document.getElementById('screen-outfit').classList.contains('active')) this.loadSuggestions();
  },

  toggleOutfitBuilder() {
    const d = document.getElementById('home-default-view');
    const b = document.getElementById('home-builder-view');
    const t = document.getElementById('outfit-builder-toggle');
    if(d.style.display === 'none') { d.style.display='block'; b.style.display='none'; t.textContent='Outfit Builder 👗'; }
    else { d.style.display='none'; b.style.display='block'; t.textContent='Back to Home 🏠'; }
  },

  currentBuilderSlot: null,
  currentBuilderCategory: null,
  async openBuilderSelect(cat, slot) {
    this.currentBuilderSlot = slot;
    this.currentBuilderCategory = cat;
    const modal = document.getElementById('builder-select-modal');
    const grid = document.getElementById('builder-select-grid');
    document.getElementById('builder-select-title').textContent = `Select ${cat}`;
    modal.style.display = 'block';
    grid.innerHTML = '<div class="spinner" style="margin:20px auto;"></div>';
    try {
      const items = await api.getWardrobe();
      const filtered = items.filter(i => {
        if(cat==='top') return i.category==='top';
        if(cat==='bottom') return i.category==='bottom';
        if(cat==='jacket') return i.category==='jacket'||i.specific_type==='Jacket';
        if(cat==='shoes') return i.category==='shoes';
        if(cat==='hat') return i.category==='hats'||i.category==='hat';
        if(cat==='jewelry') return i.category==='jewelry';
        if(cat==='watch') return i.category==='watch';
        return true;
      });
      grid.innerHTML = `
        <div style="cursor:pointer;text-align:center;padding:12px;border:1px solid var(--border-color);border-radius:var(--radius-md);display:flex;flex-direction:column;justify-content:center;align-items:center;" onclick="app.selectBuilderItem(null)">
          <div style="font-size:24px;">❌</div><div style="font-size:12px;margin-top:8px;">Clear</div>
        </div>
        ${filtered.map(i => `<div style="cursor:pointer;text-align:center;padding:4px;border:1px solid var(--border-subtle);border-radius:var(--radius-md);" onclick="app.selectBuilderItem('${i.image_path}')"><img src="${i.image_path}" style="width:100%;height:80px;object-fit:contain;"><div style="font-size:10px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${i.name}</div></div>`).join('')}
      `;
    } catch(e) { grid.innerHTML = 'Failed to load'; }
  },

  // Map slot categories to mannequin overlay element IDs
  _categoryToMannequinId: {
    'hat': 'mannequin-hat',
    'jewelry': 'mannequin-jewelry',
    'top': 'mannequin-top',
    'jacket': 'mannequin-jacket',
    'watch': 'mannequin-watch',
    'bottom': 'mannequin-bottom',
    'shoes': 'mannequin-shoes'
  },

  selectBuilderItem(imgPath) {
    if(!this.currentBuilderSlot) return;
    const cat = this.currentBuilderCategory;

    // Update the circle slot appearance
    if(imgPath) {
      this.currentBuilderSlot.style.backgroundImage = `url(${imgPath})`;
      this.currentBuilderSlot.style.backgroundSize = 'contain';
      this.currentBuilderSlot.style.backgroundPosition = 'center';
      this.currentBuilderSlot.style.backgroundRepeat = 'no-repeat';
      this.currentBuilderSlot.style.color = 'transparent';
    } else {
      this.currentBuilderSlot.style.backgroundImage = 'none';
      this.currentBuilderSlot.style.color = '';
    }

    // Update the mannequin overlay image
    const overlayId = this._categoryToMannequinId[cat];
    if(overlayId) {
      const overlayImg = document.getElementById(overlayId);
      if(overlayImg) {
        if(imgPath) {
          overlayImg.src = imgPath;
          overlayImg.style.display = 'block';
        } else {
          overlayImg.src = '';
          overlayImg.style.display = 'none';
        }
      }
    }

    document.getElementById('builder-select-modal').style.display = 'none';
  },

  toggleTempUnit(e) {
    if(e) e.stopPropagation();
    this.tempUnit = this.tempUnit === 'f' ? 'c' : 'f';
    document.querySelectorAll('.temp-toggle-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.unit === this.tempUnit);
    });
    this.updateWeatherDisplay();
  },

  updateWeatherDisplay() {
    if(!this.weatherData) return;
    const temp = this.tempUnit === 'f' ? `${this.weatherData.temperature_f}°F` : `${this.weatherData.temperature_c}°C`;
    const city = this.weatherData.city ? ` · ${this.weatherData.city}` : '';
    document.getElementById('weather-widget').innerHTML = `${temp} ${this.weatherData.condition}${city}`;
  },

  async fetchWeather() {
    // Use the browser's Geolocation API to get the user's real location
    const fetchWithCoords = async (lat, lon) => {
      try {
        const url = lat != null ? `/api/libaas/weather?lat=${lat}&lon=${lon}` : '/api/libaas/weather';
        const res = await fetch(url);
        const data = await res.json();
        this.weatherData = data;
        const cond = data.condition.toLowerCase();
        const weatherMap = { 'clear': 'summer', 'sunny': 'summer', 'snowy': 'winter', 'cloudy': 'spring', 'rainy': 'rainy' };
        this.currentWeather = weatherMap[cond] || 'summer';
        this.updateWeatherDisplay();
        this.loadDailySuggestion();

        // Reverse geocode to show city name
        if (lat != null) {
          try {
            const geoRes = await fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&zoom=10`, { headers: { 'User-Agent': 'LIBASS-Stylist/1.0' } });
            const geoData = await geoRes.json();
            const city = geoData.address?.city || geoData.address?.town || geoData.address?.village || geoData.address?.state || '';
            if (city) {
              this.weatherData.city = city;
              this.updateWeatherDisplay();
            }
          } catch(e) { /* reverse geocode is optional */ }
        }
      } catch(e) { document.getElementById('weather-widget').innerHTML = 'Weather Error'; }
    };

    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => fetchWithCoords(pos.coords.latitude.toFixed(4), pos.coords.longitude.toFixed(4)),
        () => fetchWithCoords(null, null), // user denied — fallback to default
        { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 }
      );
    } else {
      await fetchWithCoords(null, null);
    }
  },

  async loadDailySuggestion() {
    if(!this.isAuthenticated) return;
    const c = document.getElementById('home-daily-suggestion');
    c.innerHTML = '<div class="spinner" style="margin:0 auto;"></div>';
    try {
      const items = await api.getSuggestions(this.currentWeather, 'casual', this.persona);
      if(items && items.length > 0) {
        const o = items[0];
        c.innerHTML = `<div style="display:flex;flex-direction:column;width:100%;"><div style="display:flex;gap:8px;overflow-x:auto;">${o.items.map(i=>`<img src="${i.image_path}" style="width:50px;height:50px;object-fit:contain;border-radius:4px;border:1px solid var(--border-subtle);">`).join('')}</div><p style="font-size:12px;margin-top:8px;font-style:italic;color:var(--text-secondary);">${o.reasoning}</p></div>`;
      } else { c.innerHTML = 'Upload wardrobe items to get suggestions!'; }
    } catch(e) { c.innerHTML = 'Failed to load'; }
  },

  // ─── CAMERA / OUTFIT RATING ───────────────────────────────
  async submitOutfitRating() {
    if(!this.currentRatingFile) return;
    const btn = document.getElementById('rate-btn');
    btn.disabled = true; btn.textContent = '🔍 Analyzing...';
    try {
      const result = await api.rateOutfit(this.currentRatingFile);
      document.getElementById('rating-score').textContent = result.score;
      document.getElementById('rating-feedback').textContent = result.feedback;
      const impDiv = document.getElementById('rating-improvements');
      const icons = ['✨','👟','🎨'];
      impDiv.innerHTML = (result.improvements || []).map((imp,i) => `
        <div class="improvement-card">
          <div class="improvement-icon">${icons[i%3]}</div>
          <div><p style="margin:0;font-weight:600;font-size:15px;">${imp.title}</p><p style="margin:4px 0 0;font-size:13px;color:var(--text-secondary);">${imp.detail}</p></div>
        </div>
      `).join('');
      document.getElementById('camera-upload-area').style.display = 'none';
      document.getElementById('rating-results').style.display = 'block';
      this.loadPastRatings();
      this._lastRatingId = result.id;
    } catch(e) { alert("Rating failed. Please try again."); }
    btn.disabled = false; btn.textContent = '🔍 Rate My Outfit';
  },

  async saveRating() {
    const btn = document.getElementById('save-rating-btn');
    btn.disabled = true; btn.textContent = '💾 Saved!';
    // Rating is already persisted server-side during submitOutfitRating,
    // so this is a UX confirmation action
    setTimeout(() => { btn.textContent = '💾 Save Look'; btn.disabled = false; }, 2000);
  },

  resetCamera() {
    this.currentRatingFile = null;
    document.getElementById('camera-upload-area').style.display = 'block';
    document.getElementById('rating-results').style.display = 'none';
    const preview = document.getElementById('camera-preview');
    preview.innerHTML = '<div style="text-align:center;color:rgba(255,255,255,0.6);"><div style="font-size:48px;margin-bottom:12px;">📷</div><p style="font-size:14px;font-weight:500;">Tap to take or upload a photo</p></div>';
    document.getElementById('rate-btn').style.display = 'none';
  },

  async loadPastRatings() {
    const container = document.getElementById('past-ratings');
    if(!container || !this.isAuthenticated) return;
    try {
      const ratings = await api.getRatings();
      if(!ratings.length) { container.innerHTML = '<p style="font-size:13px;color:var(--text-secondary);">No past ratings yet.</p>'; return; }
      container.innerHTML = ratings.slice(0,5).map(r => `
        <div class="card mb-md" style="display:flex;gap:16px;align-items:center;">
          <img src="${r.image_path}" style="width:60px;height:60px;object-fit:cover;border-radius:var(--radius-md);">
          <div style="flex:1;">
            <span class="pill pill-coral">${r.score}/10</span>
            <p style="font-size:13px;color:var(--text-secondary);margin:4px 0 0;">${r.feedback}</p>
          </div>
        </div>
      `).join('');
    } catch(e) { container.innerHTML = ''; }
  },

  updateSpecificTypeOptions() {
    const cat = document.getElementById('ai-edit-category').value;
    const ts = document.getElementById('ai-edit-specific-type');
    const tl = document.getElementById('ai-edit-specific-type-label');
    const fs = document.getElementById('ai-edit-fit');
    const fl = document.getElementById('ai-edit-fit-label');
    ts.innerHTML = '';
    const acc = ['jewelry','watch','jacket','overpiece','shoes','hats'];
    if(acc.includes(cat)) { ts.style.display='none'; if(tl)tl.style.display='none'; fs.style.display='none'; if(fl)fl.style.display='none'; ts.innerHTML=`<option value="${cat}">${cat}</option>`; }
    else { ts.style.display='block'; if(tl)tl.style.display='block'; fs.style.display='block'; if(fl)fl.style.display='block';
      if(cat==='top') ['Shirt','T-Shirt','Jacket','Hoodie'].forEach(t=>ts.innerHTML+=`<option value="${t}">${t}</option>`);
      else if(cat==='bottom') ['Trouser','Jogger','Track pant','Skirt','Jeans'].forEach(t=>ts.innerHTML+=`<option value="${t}">${t}</option>`);
      else if(cat==='dress') ['Dress','Track suit'].forEach(t=>ts.innerHTML+=`<option value="${t}">${t}</option>`);
    }
  },

  openEditModal(item) {
    const modal = document.getElementById('ai-edit-modal');
    document.getElementById('ai-edit-img').src = item.image_path;
    document.getElementById('ai-edit-name').value = item.name;
    document.getElementById('ai-edit-fit').value = item.fit || 'regular';
    document.getElementById('ai-edit-category').value = item.category || 'top';
    document.getElementById('ai-edit-season').value = item.season || 'all';
    this.updateSpecificTypeOptions();
    const ts = document.getElementById('ai-edit-specific-type');
    const opt = Array.from(ts.options).find(o=>o.value.toLowerCase()===(item.specific_type||'').toLowerCase());
    if(opt) ts.value = opt.value;
    const btn = document.getElementById('ai-edit-confirm');
    btn.onclick = async () => {
      btn.textContent = "Saving...";
      await api.updateWardrobeItem(item.id, { name:document.getElementById('ai-edit-name').value, fit:document.getElementById('ai-edit-fit').value, category:document.getElementById('ai-edit-category').value, specific_type:document.getElementById('ai-edit-specific-type').value, season:document.getElementById('ai-edit-season').value });
      modal.style.display = 'none'; btn.textContent = "Confirm & Save"; this.loadWardrobe();
    };
    modal.style.display = 'block';
  },

  init() {
    document.querySelectorAll('.nav-tab').forEach(nav => nav.addEventListener('click', e => this.navigate(e.currentTarget.dataset.target)));

    // Upload logic
    const uploadZone = document.getElementById('upload-zone');
    const fileInput = document.getElementById('file-upload');
    uploadZone.addEventListener('click', () => fileInput.click());

    const processUpload = async (files) => {
      uploadZone.innerHTML = '<div style="padding:16px;text-align:center;"><div class="spinner" style="margin:0 auto;"></div><p style="margin-top:12px;font-weight:600;">VisionAgent is processing...</p><p style="font-size:12px;color:var(--text-secondary);">Background removal + AI tagging (10-30s per image)</p></div>';
      try {
        const res = await api.addWardrobeItem(files);
        if(Array.isArray(res) && res.length > 1) this.loadWardrobe();
        else { const item = Array.isArray(res) ? res[0] : res; this.openEditModal(item); }
      } catch(e) { alert("Upload failed"); }
      uploadZone.innerHTML = '<p style="font-weight:600;color:var(--accent-primary);">📸 Tap or drag to upload (multiple files supported)</p><p style="font-size:12px;color:var(--text-secondary);">VisionAgent will auto-crop background and identify items.</p>';
    };

    fileInput.addEventListener('change', async () => {
      if(fileInput.files.length > 0) await processUpload(fileInput.files);
    });

    // Drag-and-drop support
    uploadZone.addEventListener('dragover', (e) => { e.preventDefault(); uploadZone.style.borderColor='var(--accent-secondary)'; uploadZone.style.background='var(--accent-primary-light)'; });
    uploadZone.addEventListener('dragleave', () => { uploadZone.style.borderColor='var(--accent-primary)'; uploadZone.style.background=''; });
    uploadZone.addEventListener('drop', async (e) => {
      e.preventDefault(); uploadZone.style.borderColor='var(--accent-primary)'; uploadZone.style.background='';
      if(e.dataTransfer.files.length > 0) await processUpload(e.dataTransfer.files);
    });

    // Camera input logic
    const camInput = document.getElementById('camera-input');
    camInput.addEventListener('change', () => {
      if(camInput.files.length > 0) {
        this.currentRatingFile = camInput.files[0];
        const preview = document.getElementById('camera-preview');
        const reader = new FileReader();
        reader.onload = (e) => {
          preview.innerHTML = `<img src="${e.target.result}"><div class="camera-corners"></div>`;
          document.getElementById('rate-btn').style.display = 'block';
        };
        reader.readAsDataURL(this.currentRatingFile);
      }
    });

    this.checkAuth();
  }
};

document.addEventListener('DOMContentLoaded', () => app.init());
