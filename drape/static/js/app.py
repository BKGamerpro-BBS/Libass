const app = {
  navigate(screenId) {
    document.querySelectorAll('.screen').forEach(s => {
      s.classList.remove('active');
    });
    document.getElementById(screenId).classList.add('active');
    
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const nav = document.querySelector(`.nav-item[data-target="${screenId}"]`);
    if(nav) nav.classList.add('active');

    // Trigger lifecycle events
    if(screenId === 'screen-suggestions' && window.loadSuggestions) window.loadSuggestions();
    if(screenId === 'screen-insights' && window.loadInsights) window.loadInsights();
    if(screenId === 'screen-wardrobe' && window.loadWardrobe) window.loadWardrobe();
    if(screenId === 'screen-profile' && window.loadProfile) window.loadProfile();
  },
  init() {
    document.querySelectorAll('.nav-item').forEach(nav => {
      nav.addEventListener('click', (e) => {
        const target = e.currentTarget.dataset.target;
        this.navigate(target);
      });
    });
  }
};

document.addEventListener('DOMContentLoaded', () => {
  app.init();
});
