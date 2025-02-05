export default InputLabel = {
  mounted() {
    const container = this.el;
    const label = container.querySelector("label");
    const input = container.querySelector("input");

    input.addEventListener("focusout", event => {
      if (event.target.value !== "") {
        label.classList.add("hidden");
      } else {
        label.classList.remove("hidden");
      }
    });
  },
};

