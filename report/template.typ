#let separator(content) = {
  v(0.5em)
  grid(
    columns: (1fr, auto, 1fr),
    column-gutter: 1em,
    align(horizon, line(length: 100%, stroke: 1pt)),
    text(gray.darken(40%))[#content],
    align(horizon, line(length: 100%, stroke: 1pt)),
  )
}

#let st-user(text, value) = {
  let bg-color = if value == "red"{
    red.lighten(80%)
  } else if value == "blue" {
    blue.lighten(80%)
  } else {
    gray.lighten(70%)
  }
  table.cell(fill: bg-color)[#text]
}

#let template(
  title: "Title",
  description: "Description",
  variant: none,
  author: "John Doe",
  doc
) = {
  set document(title: title)


  let header = [
      #text(1em, "Министерство науки и высшего образования Российской Федерации Федеральное государственное автономное образовательное учреждение высшего образования") \
  #strong[«Национальный исследовательский университет ИТМО»] \
    Факультет программной инженерии и компьютерной техники (ФПИиКТ)
  ]

  let body = [
    #v(2fr)
    #align(center + horizon)[
      #text(2em, strong(title)) \
      #text(1.5em)[
        #description \
        #if variant != none [Вариант: #variant]
      ]
    ]
    #v(1fr)
    #align(bottom + right, author)
    #v(1fr)
  ]

  let footer = [Санкт-Петербург #datetime.today().year()]

  page(
    header-ascent: -40pt,
    footer-descent: 1em,
    header: align(center, header),
    footer: align(center, footer),
    align(center + horizon, body)
  )

  pagebreak()
  doc
}
