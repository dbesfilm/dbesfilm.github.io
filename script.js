document.addEventListener("DOMContentLoaded", () => {

    // Fade in kartica
    const cards = document.querySelectorAll(".project-card");

    cards.forEach((card, index) => {
        card.style.opacity = "0";
        card.style.transform = "translateY(18px)";

        setTimeout(() => {
            card.style.transition = "opacity .6s ease, transform .6s ease";
            card.style.opacity = "1";
            card.style.transform = "translateY(0)";
        }, index * 80);
    });

    // Email
    const email = "david@dbesfilm.hr";

    document
        .getElementById("emailButton")
        .addEventListener("click", () => {
            window.location.href = `mailto:${email}`;
        });

    document
        .getElementById("copyEmail")
        .addEventListener("click", async () => {

            await navigator.clipboard.writeText(email);

            const btn = document.getElementById("copyEmail");

            const original = btn.textContent;

            btn.textContent = "✓ Email kopiran";

            setTimeout(() => {
                btn.textContent = original;
            }, 1800);

        });

});