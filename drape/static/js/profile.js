document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('profile-form');
  
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = {
      height_cm: parseFloat(document.getElementById('h_cm').value),
      chest_cm: parseFloat(document.getElementById('c_cm').value),
      high_waist_cm: parseFloat(document.getElementById('hw_cm').value),
      waist_cm: parseFloat(document.getElementById('w_cm').value),
      hip_cm: parseFloat(document.getElementById('hp_cm').value)
    };
    
    try {
      const result = await api.saveProfile(data);
      if (result.body_shape) {
        // Reveal animation
        const reveal = document.getElementById('body-shape-reveal');
        document.getElementById('shape-name').textContent = result.body_shape.replace('_', ' ').toUpperCase();
        document.getElementById('shape-desc').textContent = "This is your suggested body shape based on your measurements.";
        
        reveal.classList.remove('hidden');
        reveal.animate([
          { transform: 'translateY(12px)', opacity: 0 },
          { transform: 'translateY(0)', opacity: 1 }
        ], { duration: 400, fill: 'forwards' });
      }
    } catch (e) {
      console.error(e);
    }
  });
});

window.loadProfile = async () => {
  try {
    const data = await api.getProfile();
    if (data.height_cm) {
      document.getElementById('h_cm').value = data.height_cm;
      document.getElementById('c_cm').value = data.chest_cm;
      document.getElementById('hw_cm').value = data.high_waist_cm;
      document.getElementById('w_cm').value = data.waist_cm;
      document.getElementById('hp_cm').value = data.hip_cm;
      
      if(data.body_shape) {
        const reveal = document.getElementById('body-shape-reveal');
        document.getElementById('shape-name').textContent = data.body_shape.replace('_', ' ').toUpperCase();
        document.getElementById('shape-desc').textContent = "This is your suggested body shape based on your measurements.";
        reveal.classList.remove('hidden');
      }
    }
  } catch(e) {}
};
