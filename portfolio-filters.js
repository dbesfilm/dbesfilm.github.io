// Filtriranje projekata bez promjene redoslijeda ili ponovnog učitavanja stranice.
document.addEventListener('DOMContentLoaded', () => {
  const buttons = [...document.querySelectorAll('.portfolio-filter')];
  const cards = [...document.querySelectorAll('#portfolio-grid .project-card')];
  const empty = document.getElementById('portfolio-empty');
  if (!buttons.length || !cards.length) return;

  function filterProjects(category) {
    let visible = 0;
    cards.forEach(card => {
      const show = category === 'sve' || card.dataset.category === category;
      card.hidden = !show;
      if (show) visible++;
    });
    buttons.forEach(button => {
      const active = button.dataset.filter === category;
      button.classList.toggle('is-active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    if (empty) empty.hidden = visible !== 0;
  }

  buttons.forEach(button => button.addEventListener('click', () => filterProjects(button.dataset.filter)));
  filterProjects('sve');
});
