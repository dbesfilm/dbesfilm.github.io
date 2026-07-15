document.addEventListener("DOMContentLoaded", () => {

    // Fade-in animacija kartica
    const cards = document.querySelectorAll(".project-card");

    cards.forEach((card, index) => {
        card.style.opacity = "0";
        card.style.transform = "translateY(18px)";

        setTimeout(() => {
            card.style.transition = "opacity 0.6s ease, transform 0.6s ease";
            card.style.opacity = "1";
            card.style.transform = "translateY(0)";
        }, index * 80);
    });


    // Email adresa
    const email = "david@dbesfilm.hr";


    // Gumb "Pošalji email" — izravno otvara Gmail
    const emailButton = document.getElementById("emailButton");

    if (emailButton) {
        emailButton.addEventListener("click", (event) => {
            event.preventDefault();

            const gmailUrl =
                `https://mail.google.com/mail/?view=cm&fs=1&to=${encodeURIComponent(email)}`;

            const gmailWindow = window.open(gmailUrl, "_blank");

            if (gmailWindow) {
                gmailWindow.opener = null;
            } else {
                window.location.href = gmailUrl;
            }
        });
    }


    // Gumb "Kopiraj email"
    const copyButton = document.getElementById("copyEmail");

    if (copyButton) {
        copyButton.addEventListener("click", async () => {
            try {
                await navigator.clipboard.writeText(email);

                const originalText = copyButton.textContent;

                copyButton.textContent = "✓ Email kopiran";

                setTimeout(() => {
                    copyButton.textContent = originalText;
                }, 1800);

            } catch (error) {
                alert(`Email: ${email}`);
            }
        });
    }


    // Header gumb "Kontakt"
    const contactLink = document.querySelector(".contact-link");
    const contactSection = document.getElementById("kontakt");

    if (contactLink && contactSection) {
        contactLink.addEventListener("click", (event) => {
            event.preventDefault();

            contactSection.scrollIntoView({
                behavior: "smooth",
                block: "start"
            });
        });
    }

});