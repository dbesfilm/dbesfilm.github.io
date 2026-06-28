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

    // Pošalji email
    const emailButton = document.getElementById("emailButton");

    if (emailButton) {
        emailButton.addEventListener("click", (e) => {
            e.preventDefault();
            window.location.href = `mailto:${email}`;
        });
    }

    // Kopiraj email
    const copyButton = document.getElementById("copyEmail");

    if (copyButton) {
        copyButton.addEventListener("click", async () => {

            try {
                await navigator.clipboard.writeText(email);

                const original = copyButton.textContent;

                copyButton.textContent = "✓ Email kopiran";

                setTimeout(() => {
                    copyButton.textContent = original;
                }, 1800);

            } catch (err) {
                alert(email);
            }

        });
    }

    // Header "Kontakt"
    const contactLink = document.querySelector(".contact-link");
    const contactSection = document.getElementById("kontakt");

    if (contactLink && contactSection) {

        contactLink.addEventListener("click", (e) => {

            e.preventDefault();

            contactSection.scrollIntoView({
                behavior: "smooth",
                block: "start"
            });

        });

    }

});