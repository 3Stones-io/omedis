export default {
  mounted() {
    console.log('TimelineCalendarDateSelector mounted')
  }
}
// Update the date selector date text -> default to today
// Button to go to previous day
// Button to go to next day
// Each click shaould send an event to the server to fetch events for the selected day
// Server -> Seed events for various dates
