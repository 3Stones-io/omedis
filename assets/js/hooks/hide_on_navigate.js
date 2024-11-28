export default HideOnNavigate = {
  mounted() {
    window.addEventListener("phx:navigate", () => {
      this.el.removeAttribute("style");
    });
  },
};
