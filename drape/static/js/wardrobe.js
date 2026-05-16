document.addEventListener('DOMContentLoaded', () => {
  const uploadZone = document.getElementById('upload-zone');
  const fileInput = document.getElementById('file-upload');
  const form = document.getElementById('upload-form');
  
  uploadZone.addEventListener('click', () => fileInput.click());
  
  fileInput.addEventListener('change', () => {
    if (fileInput.files.length > 0) {
      form.classList.remove('hidden');
      uploadZone.innerHTML = `<p>Selected: ${fileInput.files[0].name}</p>`;
    }
  });
  
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!fileInput.files.length) return;
    
    const formData = new FormData();
    formData.append('image', fileInput.files[0]);
    formData.append('name', document.getElementById('item_name').value);
    formData.append('category', document.getElementById('item_category').value);
    formData.append('color', document.getElementById('item_color').value);
    formData.append('pattern', document.getElementById('item_pattern').value);
    formData.append('fit', document.getElementById('item_fit').value);
    formData.append('occasion', document.getElementById('item_occasion').value);
    formData.append('season', document.getElementById('item_season').value);
    
    try {
      await api.addWardrobeItem(formData);
      form.reset();
      form.classList.add('hidden');
      uploadZone.innerHTML = `<p>Tap or drag to upload an item</p>`;
      window.loadWardrobe();
    } catch (err) {
      console.error(err);
    }
  });
});

window.loadWardrobe = async () => {
  const grid = document.getElementById('wardrobe-grid');
  grid.innerHTML = '<p>Loading...</p>';
  try {
    const items = await api.getWardrobe();
    if (items.length === 0) {
      grid.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--text-secondary);">Your wardrobe is waiting. Add your first piece.</div>`;
      return;
    }
    
    grid.innerHTML = items.map(item => `
      <div class="card" style="position: relative;">
        <img src="${item.image_path}" style="width: 100%; height: 150px; object-fit: cover; border-radius: 8px;">
        <h4 style="margin: 8px 0 4px 0;">${item.name}</h4>
        <span class="fit-badge ${item.fit}">${item.fit}</span>
        <button onclick="deleteItem('${item.id}')" class="btn-ghost" style="position: absolute; top: 8px; right: 8px; padding: 4px 8px; font-size: 10px; border: none; background: rgba(255,255,255,0.8);">X</button>
      </div>
    `).join('');
  } catch(e) {
    grid.innerHTML = '<p>Error loading wardrobe.</p>';
  }
};

window.deleteItem = async (id) => {
  if(confirm("Delete this item?")) {
    await api.deleteWardrobeItem(id);
    window.loadWardrobe();
  }
};
