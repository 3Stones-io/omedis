export default SearchActivityInput = {
  mounted() {
    const hook = this
    const searchInputField = hook.el
    const activitiesList = document.querySelector("#activities-list")
    const searchActivitiesList = document.querySelector("#search-activities-list-container")

    console.log(searchActivitiesList)

    searchInputField.addEventListener("input", (event) => {
      let searchQuery = event.target.value.trim()
      if (searchQuery !== "") {
        hook.pushEventTo(
          "#time-tracking-container",
          "search-activity",
          { activity_query: searchQuery }
        )

        activitiesList.classList.add("hidden")
        searchActivitiesList.classList.remove("hidden")

      } else {
        activitiesList.classList.remove("hidden")
        searchActivitiesList.classList.add("hidden")
      }
    })
  }
}

