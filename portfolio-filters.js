// Filtriranje kartica bez promjene redoslijeda i bez ponovnog učitavanja.
document.addEventListener('DOMContentLoaded', () => {
  const select = document.getElementById('portfolio-filter');
  const cards = [...document.querySelectorAll('#portfolio-grid .project-card')];
  const empty = document.getElementById('portfolio-empty');
  if (!select || !cards.length) return;

  const filterProjects = (category) => {
    let visible = 0;
    cards.forEach(card => {
      const show = category === 'sve' || card.dataset.category === category;
      card.hidden = !show;
      if (show) visible++;
    });
    if (empty) empty.hidden = visible > 0;
  };

  select.addEventListener('change', () => filterProjects(select.value));
  filterProjects(select.value);
});
