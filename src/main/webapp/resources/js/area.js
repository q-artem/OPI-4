const canvas = document.getElementById("canvas")
const ctx = canvas.getContext("2d")

canvas.width = 1024
canvas.height = 1024
const scale = 85

function drawLine(fx, fy, tx, ty, w, color) {
  ctx.lineWidth = w
  ctx.strokeStyle = color

  ctx.beginPath()
  ctx.moveTo(fx, fy)
  ctx.lineTo(tx, ty)
  ctx.stroke()
}

function drawPoly(points, w, color) {
  ctx.lineWidth = w
  ctx.strokeStyle = color

  ctx.beginPath()
  ctx.moveTo(points[0][0], points[0][1])
  for (let i = 1; i < points.length; i++) {
    ctx.lineTo(points[i][0], points[i][1])
  }
  ctx.stroke()
}

function drawTriangle(x1, y1, x2, y2, x3, y3, color) {
  ctx.fillStyle = color

  ctx.beginPath()
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)
  ctx.lineTo(x3, y3)
  ctx.fill()
}

function drawRect(x, y, w, h, color) {
  ctx.fillStyle = color

  ctx.fillRect(x, y, w, h)
}

function drawArc(cx, cy, r, sa, ea, color) {
  ctx.fillStyle = color

  ctx.beginPath()
  ctx.lineTo(cx, cy)
  ctx.arc(cx, cy, r, sa, ea)
  ctx.fill()
}

function drawStrokeArc(cx, cy, r, sa, ea, w, color) {
  ctx.lineWidth = w
  ctx.strokeStyle = color

  ctx.beginPath()
  ctx.arc(cx, cy, r, sa, ea)
  ctx.stroke()
}

function drawText(text, x, y, fontsize) {
  ctx.font = `${fontsize}px monospace`

  ctx.fillText(text, x, y)
}

function drawCanvas(r, cp, points) {
  const style = window.getComputedStyle(document.body)
  const colors = {
    primary: style.getPropertyValue("--color-primary"),
    secondary: style.getPropertyValue("--color-secondary"),
    tertiary: style.getPropertyValue("--color-tertiary"),
    primary_transperent: style.getPropertyValue("--color-primary-transparent"),
    surface: style.getPropertyValue("--color-surface"),
    on_surface: style.getPropertyValue("--color-on-surface")
  }

  const w = canvas.width
  const h = canvas.height
  r *= scale

  drawRect(0, 0, w, h, colors.surface)

  drawLine(w / 2, 10, w / 2, h, 5, colors.on_surface)
  drawLine(0, h / 2, w - 10, h / 2, 5, colors.on_surface)

  drawTriangle(
    w / 2, 0,
    w / 2 - 15, 40,
    w / 2 + 15, 40,
    colors.on_surface
  )
  drawTriangle(
    w, h / 2,
    w - 40, h / 2 - 15,
    w - 40, h / 2 + 15,
    colors.on_surface
  )

  drawLine(
    w / 2 - 10, h / 2 + 10,
    w / 2 + 10, h / 2 - 10,
    5, colors.on_surface
  )
  drawText("0", w / 2 - 35, h / 2 + 40, 30)

  for (let i = 1; i <= 5; i++) {
    let j = i * scale

    drawLine(
      w / 2 - 10, h / 2 - j,
      w / 2 + 10, h / 2 - j,
      5, colors.on_surface
    )
    drawText(i, w / 2 + 15, h / 2 + 10 - j, 30)

    drawLine(
      w / 2 - 10, h / 2 + j,
      w / 2 + 10, h / 2 + j,
      5, colors.on_surface
    )
    drawText(-i, w / 2 + 15, h / 2 + 10 + j, 30)

    drawLine(
      w / 2 - j, h / 2 + 10,
      w / 2 - j, h / 2 - 10,
      5, colors.on_surface
    )
    drawText(-i, w / 2 - 10 - j, h / 2 - 25, 30)

    drawLine(
      w / 2 + j, h / 2 + 10,
      w / 2 + j, h / 2 - 10,
      5, colors.on_surface
    )
    drawText(i, w / 2 - 10 + j, h / 2 - 25, 30)
  }

  drawArc(
    w / 2, h / 2, r,
    0, Math.PI / 2,
    colors.primary_transperent
  )
  drawTriangle(
    w / 2, h / 2,
    w / 2, h / 2 - r,
    w / 2 - r, h / 2,
    colors.primary_transperent
  )
  drawRect(
    w / 2, h / 2,
    -r / 2, r,
    colors.primary_transperent
  )

  drawStrokeArc(
    w / 2, h / 2, r,
    0, Math.PI / 2,
    10, colors.primary
  )
  drawPoly(
    [
      [w / 2, h / 2 + r],
      [w / 2 - r / 2, h / 2 + r],
      [w / 2 - r / 2, h / 2],
      [w / 2 - r, h / 2],
      [w / 2, h / 2 - r],
      [w / 2, h / 2],
      [w / 2 + r, h / 2],
    ],
    10, colors.primary
  )

  drawStrokeArc(
    w / 2 + cp[0] * scale, h / 2 - cp[1] * scale, 5,
    0, 2 * Math.PI,
    10, colors.tertiary
  )

  for (let p of points) {
    drawStrokeArc(
      w / 2 + p[0] * scale, h / 2 - p[1] * scale, 2,
      0, 2 * Math.PI,
      10, colors.secondary
    )
  }
}

function addCanvasClickListener(fn) {
  canvas.addEventListener("click", e => {
    const r = canvas.getBoundingClientRect()
    const x = (e.clientX - r.left) / r.width * canvas.width - canvas.width / 2
    const y = (e.clientY - r.top) / r.height * canvas.height - canvas.height / 2
    fn(x / scale, -y / scale)
  })
}

function getX() {
  return PF("vx").getValue()
}

function getY() {
  return PF("vy").getValue()
}

function getR() {
  if (PF("vr1").isChecked()) return 1
  if (PF("vr15").isChecked()) return 1.5
  if (PF("vr2").isChecked()) return 2
  if (PF("vr25").isChecked()) return 2.5
  if (PF("vr3").isChecked()) return 3
}

function setX(x) {
  PF("vx").setValue(Math.round(x))
}

function setY(y) {
  PF("vy").setValue(y)
}

function setR(r) {
  PF("vr1").uncheck()
  PF("vr15").uncheck()
  PF("vr2").uncheck()
  PF("vr25").uncheck()
  PF("vr3").uncheck()

  if (r === 1) PF("vr1").check()
  if (r === 1.5) PF("vr15").check()
  if (r === 2) PF("vr2").check()
  if (r === 2.5) PF("vr25").check()
  if (r === 3) PF("vr3").check()
}

function keepOneR(c) {
  const widgets = ["vr1", "vr15", "vr2", "vr25", "vr3"]

  if (!PF(c).isChecked()) return

  for (let w of widgets) {
    if (w !== c) {
      PF(w).uncheck()
    }
  }
}

function getPoints() {
  let cr = getR()

  return points = $("#result-table tbody tr").map(function() {
    let $cells = $(this).children("td")

    let xStr = $cells.eq(1).text().trim().replace(",", ".")
    let yStr = $cells.eq(2).text().trim().replace(",", ".")
    let rStr = $cells.eq(3).text().trim().replace(",", ".")

    let x = parseFloat(xStr)
    let y = parseFloat(yStr)
    let r = parseFloat(rStr)

    if (!isNaN(x) && !isNaN(y) && !isNaN(r) && r === cr) {
      return [[x, y]]
    }
  }).get()
}

$(document).ready(function() {
  drawCanvas(getR(), [getX(), getY()], getPoints())
})

$("input[id$='x-field_input']").on("change keyup", function() {
  drawCanvas(getR(), [getX(), getY()], getPoints())
})

$(".ui-spinner-button").on("click", function() {
  drawCanvas(getR(), [getX(), getY()], getPoints())
})

$("input[id$='y-field_input']").on("change keyup", function() {
  drawCanvas(getR(), [getX(), getY()], getPoints())
})

$("div.radio-container input[type='checkbox']").on("change", function() {
  drawCanvas(getR(), [getX(), getY()], getPoints())
})

window
  .matchMedia("(prefers-color-scheme: light)")
  .addEventListener("change", () => { drawCanvas(getR(), [getX(), getY()], getPoints()) })

addCanvasClickListener((x, y) => {
  setX(x)
  setY(y)
  drawCanvas(getR(), [getX(), getY()], getPoints())
})
