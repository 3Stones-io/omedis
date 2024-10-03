let LogCategoryPositionInputHooks = {}

LogCategoryPositionInputHooks.LogCategoryPositionInput = {
  mounted() {
    let inputEl = this.el

    // prevent click event from opening the /log_category/:id page
    inputEl.addEventListener('click', event => {
      event.preventDefault()
      event.stopPropagation()
    })
  },
}

export default LogCategoryPositionInputHooks
