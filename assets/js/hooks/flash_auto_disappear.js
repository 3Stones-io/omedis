export default FlashAutoDisappear = {
  mounted() {
    if (!this.el.hidden) {
      let delay = this.el.dataset.delay

      setTimeout(() => {
        this.el.click()
      }, delay * 1000)
    }
  },
}
