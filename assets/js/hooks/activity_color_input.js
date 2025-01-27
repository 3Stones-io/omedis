export default ActivityColorInput = {
  mounted() {
    const container = this.el
    const colorPickerInput = container.querySelector("#color-picker-input")
    const colorPickerRadio = container.querySelectorAll(".activity-color-radio")
    const colorPickerInputText = container.querySelector("#color-picker-input-text")
    const colorCodeInput = document.querySelector("#color-code-input")
  
    const selectColor = color => {
      colorCodeInput.value = color
      colorCodeInput.dispatchEvent(new Event("input", { bubbles: true }))
      colorPickerInputText.value = color
    }

    const selectRadioColor = radio => {
      colorPickerRadio.forEach(r => {
        r.nextElementSibling.classList.remove("checked-radio")
      })
      if (radio.checked) {
        radio.nextElementSibling.classList.add("checked-radio")
      }
    }

    colorPickerInput.addEventListener("change", (event) => {
      event.preventDefault()
      selectColor(event.target.value)
    })

    colorPickerRadio.forEach(radio => {
      // To override double click to select the radio button
      radio.addEventListener("click", (event) => {
        event.preventDefault()
        
        radio.dispatchEvent(new Event("change"))  
      })

      radio.addEventListener("change", (event) => {
        event.preventDefault()
        selectRadioColor(radio)
        radio.value && selectColor(radio.value)
      })
    })
  }
}
