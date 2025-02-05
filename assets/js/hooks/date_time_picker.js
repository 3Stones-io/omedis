import flatpickr from "flatpickr";

export default DateTimePicker = {
  mounted() {
    const input = this.el;
    const label = input.previousElementSibling;
   
    flatpickr(input, {
      dateFormat: "d-m-Y",
    });

    input.addEventListener("input", (event) => {
      if (event.target.value !== "") {
        label.classList.add("hidden");
      }
    });
  },
};

