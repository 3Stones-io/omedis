let SlugInputHooks = {}

SlugInputHooks.SlugInput = {
  mounted() {
    let hook = this
    let input = this.el
    
    hook.handleEvent("update-slug", data => {
      input.value = data.slug
      input.dispatchEvent(new Event('input', { bubbles: true }))
    })
  },
}

export default SlugInputHooks