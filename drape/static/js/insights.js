window.loadInsights = async () => {
  const content = document.getElementById('insights-content');
  content.innerHTML = '<p>Loading...</p>';
  try {
    const data = await api.getInsights();
    content.innerHTML = `
      <div class="card">
        <h3>Missing Pieces</h3>
        <ul style="color: var(--text-secondary);">
          ${data.missing.map(m => `<li>${m}</li>`).join('')}
        </ul>
        <h3>What works for your shape</h3>
        <p style="color: var(--text-secondary);">${data.tips}</p>
      </div>
    `;
  } catch(e) {
    content.innerHTML = '<p>Error loading insights.</p>';
  }
};
