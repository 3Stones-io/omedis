import * as d3 from "d3"

export default TimelineCalendar = {
  mounted() {
    createTimelineCalendar(this.el)
  },
  updated() {
    createTimelineCalendar(this.el)
  }
}

function createTimelineCalendar(calendarElement) {
  const dailyStartAt = calendarElement.dataset.dailyStartAt
  const dailyEndAt = calendarElement.dataset.dailyEndAt
  const events = JSON.parse(calendarElement.dataset.events)

  // Parse time range
  const parseTimeRange = startOrEndTime => {
    const baseDate = new Date()
    baseDate.setHours(0, 0, 0, 0)

    const [hours, minutes] = startOrEndTime.split(':')

    const time = new Date(baseDate)
    time.setHours(parseInt(hours), parseInt(minutes), 0)

    return time
  }

  // Define colors
  const colors = {
    axis: 'var(--timeline-axis-color, rgba(0, 0, 0, 0.5))',
    grid: 'var(--timeline-grid-color, rgba(0, 0, 0, 0.3))',
    border: 'var(--timeline-border-color, rgba(0, 0, 0, 0.3))',
    timeIndicator: 'var(--timeline-indicator-color, #ff0000)',
    durationText: 'var(--timeline-duration-color, #666)'
  }

  // Parse time range
  const startTime = parseTimeRange(dailyStartAt)
  const endTime = parseTimeRange(dailyEndAt)

  // Add padding hours to the start and end times
  const paddedStartTime = new Date(startTime)
  paddedStartTime.setHours(startTime.getHours() - 1)
  const paddedEndTime = new Date(endTime)
  paddedEndTime.setHours(endTime.getHours() + 1)

  // Get the container's dimensions
  const containerWidth = calendarElement.clientWidth
  const containerHeight = calendarElement.clientHeight

  // Define margin, barWidth
  const margin = {
    top: Math.round(containerHeight * 0.003),
    right: Math.round(containerWidth * 0.03),
    bottom: Math.round(containerHeight * 0.01),
    left: Math.round(containerWidth * 0.10)
  }

  const barWidth = Math.round(containerWidth * 0.6)

  // Create svg for the calendar
  const svg =
    d3.create('svg')
      .attr('width', '100%')
      .attr('height', '100%')
      .attr("viewBox", `0 0 ${containerWidth} ${containerHeight}`)
      .attr("preserveAspectRatio", "xMidYMid meet")

  // Create yScale for the calendar
  const yScale =
    d3.scaleTime()
      .domain([paddedStartTime, paddedEndTime])
      .range([margin.top, containerHeight - margin.bottom])

  // Create yAxis for the calendar
  const yAxis =
    d3.axisLeft()
      .ticks(d3.timeHour.every(1))
      .scale(yScale)
      .tickSize(0)
      .tickFormat((d) => {
        if (d >= startTime && d <= endTime) {
          return d3.timeFormat('%H:%M')(d)
        }
        return ''
      })

  // Create yAxisGroup for the calendar
  const yAxisGroup =
    svg.append('g')
      .attr('transform', `translate(${margin.left}, 0)`)
      .attr('opacity', 1)
      .style('color', colors.axis)
      .call(yAxis)

  const fontSize = Math.max(0.75, Math.round(containerWidth * 0.00075)) + 'rem'
  const timelineOffset = Math.round(containerWidth * 0.2) // 40% remains :: put in the middle

  yAxisGroup.selectAll('text')
    .style('font-size', fontSize)
    .style('font-family', 'Open Sans, serif')
    .attr('dx', `-${parseFloat(fontSize) * 16 * 0.2}px`)

  // Remove the domain line (main vertical axis line)
  yAxisGroup.select('.domain').remove()

  // Create middle gridLines for the calendar
  const gridLines =
    d3.axisRight()
      .ticks(d3.timeHour.every(1))
      .tickSize(barWidth)
      .tickFormat('')
      .scale(yScale)

  const gridGroup = svg
    .append('g')
    .attr('transform', `translate(${margin.left},0)`)
    .style('color', colors.grid)
    .call(gridLines)

  // Remove the domain and the first/last grid lines
  gridGroup.select('.domain').remove()
  gridGroup.selectAll('.tick line')
    .filter((d, i, nodes) => i === 0 || i === nodes.length - 1)
    .remove()

  // Add horizontal bottom line to gridGroup and vertical to the far right
  gridGroup
    .append('line')
    .attr('x1', - margin.left)
    .attr('y1', containerHeight - margin.bottom)
    .attr('x2', barWidth + timelineOffset + margin.left)
    .attr('y2', containerHeight - margin.bottom)
    .attr('stroke', colors.grid)

  svg
    .append('line')
    .attr('x1', margin.left)
    .attr('y1', margin.top)
    .attr('x2', margin.left)
    .attr('y2', containerHeight - margin.bottom)
    .attr('stroke', colors.border)

  svg
    .append('line')
    .attr('x1', margin.left + barWidth)
    .attr('y1', margin.top)
    .attr('x2', margin.left + barWidth)
    .attr('y2', containerHeight - margin.bottom)
    .attr('stroke', colors.border)

  const timelineGroup = svg
    .append('g')
    .attr('transform', `translate(${margin.left + barWidth + timelineOffset}, 0)`)

  // Add vertical line for events
  timelineGroup
    .append('line')
    .attr('x1', 0)
    .attr('y1', margin.top)
    .attr('x2', 0)
    .attr('y2', containerHeight - margin.bottom)
    .attr('stroke', colors.border)

  const eventRadius = Math.max(4, Math.round(containerWidth * 0.008))
  timelineGroup
    .selectAll('rect')
    .data(events)
    .enter()
    .append('rect')
    .attr('x', -Math.round(eventRadius))
    .attr('y', d => {
      const time = parseTimeRange(d.dtstart)
      return yScale(time)
    })
    .attr('width', eventRadius * 2)
    .attr('height', d => {
      const start = parseTimeRange(d.dtstart)
      const end = parseTimeRange(d.dtend)
      return yScale(end) - yScale(start)
    })
    .attr('rx', eventRadius)
    .attr('ry', eventRadius)
    .attr('fill', d => d.activity_color)
    .attr('opacity', 0.8)

  timelineGroup
    .selectAll('text')
    .data(events)
    .enter()
    .append('text')
    .attr('x', -Math.round(containerWidth * 0.025))
    .attr('y', d => {
      const end = parseTimeRange(d.dtend)
      return yScale(end) - 5
    })
    .text(d => {
      const start = parseTimeRange(d.dtstart)
      const end = parseTimeRange(d.dtend)
      const duration = (end - start) / (1000 * 60)
      const hours = Math.floor(duration / 60)
      const minutes = Math.floor(duration % 60)
      return hours > 0 ? `${hours}h ${minutes}min` : `${minutes}min`
    })
    .attr('fill', colors.durationText)
    .attr('font-size', `.7rem`)
    .attr('font-family', 'Open Sans, serif')
    .attr('text-anchor', 'end')

  setInterval(() => {
    const now = new Date()

    if (now >= startTime && now <= endTime) {
      svg.selectAll('.time-indicator').remove()

      const timeIndicator = svg.append('g')
        .attr('class', 'time-indicator')

      timeIndicator.append('line')
        .attr('x1', margin.left)
        .attr('x2', margin.left + barWidth + timelineOffset - Math.round(containerWidth * 0.011))
        .attr('y1', yScale(now))
        .attr('y2', yScale(now))
        .attr('stroke', colors.timeIndicator)
        .attr('stroke-width', Math.max(2, containerWidth * 0.002))

      const indicatorRadius = Math.max(3, Math.round(containerWidth * 0.003))
      timeIndicator.append('circle')
        .attr('cx', margin.left + 2)
        .attr('cy', yScale(now))
        .attr('r', indicatorRadius)
        .attr('fill', colors.timeIndicator)
    }
  }, 1000)

  calendarElement.appendChild(svg.node())
}
