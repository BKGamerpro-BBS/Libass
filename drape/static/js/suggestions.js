window.loadSuggestions = async () => {
  const grid = document.getElementById('suggestions-grid');
  grid.innerHTML = '<p>Loading...</p>';
  try {
    const data = await api.getSuggestions();
    if (!data.length) {
      grid.innerHTML = '<p>Upload a few more items and we\\'ll find your perfect looks.</p>';
      return;
    }
    grid.innerHTML = data.map(outfit => `
      <div class="card" style="border-left: 4px solid var(--accent-primary);">
        <span class="label" style="background: var(--bg-surface); padding: 4px 8px; border-radius: 12px;">${outfit.occasion}</span>
        <div style="display: flex; gap: 8px; margin-top: 12px; overflow-x: auto; padding-bottom: 8px;">
          ${outfit.items.map(item_id => `<div style="width: 56px; height: 56px; background: #eee; border-radius: 8px;">Item ${item_id}</div>`).join('')}
        </div>
        <div style="margin-top: 12px;">
          <div style="height: 4px; background: var(--border-color); border-radius: 2px;">
            <div style="width: ${outfit.body_shape_score * 10}%; height: 100%; background: var(--accent-primary); border-radius: 2px;"></div>
          </div>
        </div>
        <p style="font-style: italic; color: var(--text-secondary); margin-top: 12px;">${outfit.reasoning}</p>
      </div>
    `).join('');
  } catch(e) {
    grid.innerHTML = '<p>Error loading suggestions.</p>';
  }
};
