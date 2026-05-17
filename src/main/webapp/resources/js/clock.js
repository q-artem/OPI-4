const time = document.getElementById("time")
const date = document.getElementById("date")

function updateTime() {
  let now = new Date()
  time.innerText = now.toLocaleTimeString()
}

function updateDate() {
  let now = new Date()
  date.innerText = now.toLocaleDateString(undefined, { year: "numeric", month: "long", day: "numeric" })
}

updateTime()
updateDate()
setInterval(updateTime, 1000)
setInterval(updateDate, 1000)
