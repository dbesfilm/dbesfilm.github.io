document.addEventListener("DOMContentLoaded", () => {
  const cards = document.querySelectorAll(".project-card");

  cards.forEach((card, index) => {
    card.style.opacity = "0";
    card.style.transform = "translateY(18px)";

    setTimeout(() => {
      card.style.transition = "opacity 600ms ease, transform 600ms ease";
      card.style.opacity = "1";
      card.style.transform = "translateY(0)";
    }, 90 * index);
  });
});