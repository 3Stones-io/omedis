const dateString = (daysFrom, date) => {
  date.setDate(date.getDate() + daysFrom)
  const isToday = date.toDateString() === new Date().toDateString()
  return isToday ? `Today - ${date.toLocaleDateString('en-us', { weekday:"short", day:"numeric", month:"short" })}` : date.toLocaleDateString('en-us', { weekday:"short", day:"numeric", month:"short" })
}

export default {
  mounted() {
    const hook = this
    const dateSelector = hook.el
    const dateSelectorDate = dateSelector.querySelector('#timeline-calendar-date-selector-date')
    const dateSelectorPreviousButton = dateSelector.querySelector('#timeline-calendar-date-selector-previous')
    const dateSelectorNextButton = dateSelector.querySelector('#timeline-calendar-date-selector-next')

    this.currentDate = new Date()

    dateSelectorDate.textContent = dateString(0, this.currentDate)

    dateSelectorPreviousButton.addEventListener('click', () => {
      this.currentDate = new Date(this.currentDate.setDate(this.currentDate.getDate() - 1))
      dateSelectorDate.textContent = `${dateString(0, this.currentDate)}`
      hook.pushEvent('fetch-events', { date: this.currentDate })
    })

    dateSelectorNextButton.addEventListener('click', () => {
      this.currentDate = new Date(this.currentDate.setDate(this.currentDate.getDate() + 1))
      dateSelectorDate.textContent = `${dateString(0, this.currentDate)}`
      hook.pushEvent('fetch-events', { date: this.currentDate })
    })
  },
  updated() {
    this.el.querySelector('#timeline-calendar-date-selector-date').textContent = dateString(0, this.currentDate)
  }
}
