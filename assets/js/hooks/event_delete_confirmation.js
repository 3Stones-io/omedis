export default eventDeleteConfirmation = {
  mounted() {
    
    setTimeout(() => {
      this.pushEvent("hide-delete-confirmation")
    }, 2000)
  },
}

