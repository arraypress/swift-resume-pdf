# Swift Resume PDF

Résumés, CVs and cover letters as PDFs. Fourteen designs, real typography, and the checks that decide whether the thing gets read.

```swift
let resume = Resume(
    profile: Profile(
        name: "Alex Moreau",
        headline: "Senior Infrastructure Engineer",
        location: "London, UK",
        email: "alex@moreau.dev",
        links: [Link("https://github.com/alexmoreau")]
    ),
    summary: "Infrastructure engineer with eleven years on payment and ledger systems.",
    experience: [
        Position(
            role: "Senior Infrastructure Engineer",
            organisation: "Stripe",
            location: "London",
            dates: .since("Mar 2022"),
            highlights: ["Took p99 commit latency from 340ms to 45ms."]
        )
    ]
)

try resume.save(to: url, design: .ledger)     // 54 KB
```

## Why

Most applications are not read by a person first. They are parsed by an applicant tracking system, which extracts the text, guesses which block is the employment history, and scores the result against the posting.

So a résumé has two audiences with opposite tastes, and the tools mostly serve one. The template that looks best is two columns with the contact details in a sidebar — which is precisely the layout that comes out of a parser as a phone number in the middle of an employment history. Nobody reads that. It gets scored, and it scores badly.

This writes the PDF directly, in designs that are honest about which side of that line they fall on. There is no browser engine, no service, and nothing leaves the machine.

## Features

- ✒️ **Real typography** — Inter, Source Serif 4 and JetBrains Mono travel with the package, in several weights and italic
- 🎨 **Fourteen designs** — genuinely different arrangements, not one with the colours changed
- ✉️ **Cover letters** — four letter designs, each paired with a résumé one
- 🌗 **Light, dark and tinted** — a property of the theme, so every design gets all three
- 🤖 **ATS checks** — column layout, heading names, date formats, ordering, length
- 🌍 **Regional conventions** — what a Lebenslauf must carry and a US résumé must not
- 📄 **Multi-page** — footers know the page count, entries do not split from their headings
- 🔤 **Any Latin, Greek or Cyrillic name** — subset and embedded, and still selectable afterwards
- 📦 **One dependency** — [swift-text-pdf](https://github.com/arraypress/swift-text-pdf), which has none
- 🪶 **~50 KB out** — three subset faces and a page of text

## The designs

| Design | For | Parseable |
|---|---|---|
| `ledger` | Single column, ruled sections, sans. The default. | ✅ |
| `broadsheet` | Serif, centred masthead. Academic, legal, formal. | ✅ |
| `timeline` | Dates in a rail down the left edge. | ✅ |
| `margin` | Section names hung in the left margin. Book typography. | ✅ |
| `nocturne` | Light masthead band, the rest of the page reversed. | ✅ |
| `plaque` | A coloured panel across the top, name knocked out of it. | ✅ |
| `bulletin` | Headings as tabs, each with a mark. Navigable at a glance. | ✅ |
| `register` | Alternating tinted section bands, labels in the margin. | ✅ |
| `marker` | Headings struck through with a highlighter. Informal. | ✅ |
| `slate` | Twin masthead panels and a tab beside every section. | ✅ |
| `swiss` | An oversized name and a great deal of air. | ✅ |
| `card` | Every entry on a panel of its own. | ✅ |
| `terminal` | Monospaced labels and dates, proportional prose. | ✅ |
| `sidebar` | Tinted rail carrying contact and skills. | ❌ |

`sidebar` is the best-looking of the fourteen and the only one a tracking system cannot read. That is not a bug to be fixed later — two columns and machine-readability are the same trade-off seen from either end. Send it where a person will open it, and use one of the others for anything that goes through a form. `check` says so rather than leaving it to be discovered.

## Themes, not templates

Most of what looks like a dozen résumé designs is four arrangements in a dozen colourways. That is an axis of the theme here, so every design gets it:

```swift
Theme(accent: "#1F3A5F")                        // an ink blue
Theme(accent: "#E8A33D", scheme: .dark)         // reversed out
Theme(accent: "#7A4A2B", tint: "#F6F1E8")       // on warm paper
Theme(density: .compact)                        // six more lines per page
```

An accent chosen against white is routinely invisible on a dark page, so it is lifted when it comes too close to the background and left alone when it does not. A design that inverts a band gets a palette derived from that band, so bullets, dates and rules inside it stay legible without knowing anything unusual is happening.

## Résumé, CV, or letter

Two documents, not three. A résumé and a CV are the same data under different conventions — length, ordering, and what is included — so both are a `Resume`, and the conventions are parameters:

```swift
Resume(profile: profile, experience: roles, order: .conventional)   // a résumé
Resume(profile: profile, grants: funding, order: .academic)         // a CV
```

`Section.academic` leads with publications and funding; `Section.graduate` leads with the degree. `Region` supplies the rest — a US résumé is one page and carries no date of birth, a Lebenslauf carries one.

A CV has sections a résumé does not, and those are real:

| | |
|---|---|
| `grants` | Funding, with the funder, the amount, the period and whether you led it |
| `teaching` | Courses taught |
| `talks` | Given, invited or otherwise |
| `service` | Reviewing, editorial work, committees |
| `memberships` | Professional bodies |

A cover letter *is* a different document, so it is a different type. See below.

## Building your own

Three things are open, and they are the three that matter:

**Sections.** `Section` is a struct, not an enum, so the set is not fixed.

**Typefaces.** Bring your own — static TrueType, any weights you have:

```swift
let mine = Typeface.custom(
    name: "Söhne",
    regular: regularURL,
    semibold: semiboldURL,
    italic: italicURL
)
try resume.save(to: url, theme: Theme(typeface: mine))
```

Only the weights you supply exist; a design asking for one you left out gets the nearest you did, so a family of two files renders everything.

**Designs.** `Design`, `Sheet` and `Blocks` are public, so a layout of your own is a masthead and a loop:

```swift
struct Broadside: Design {
    func render(_ resume: Resume, on sheet: Sheet) {
        sheet.line(resume.profile.name, size: 30, face: sheet.semibold)
        sheet.rule(color: sheet.accent, thickness: 2)

        let style = Blocks.Style(x: sheet.left, width: sheet.width)
        for section in resume.populated() {
            sheet.sectionHeading(resume.heading(for: section))
            Blocks.render(section, of: resume, on: sheet, style: style)
        }
    }
}

try resume.save(to: url, design: Broadside())
```

`Blocks` renders any section exactly as the built-in designs do, so you inherit page breaking, the date placement rules and every entry shape. `Sheet` carries the rest — the palette, the vertical rhythm, and the components: `chips`, `dots`, `dial`, `gauge`, `icon`, `portrait`, `runOn`, `contactFlow`. `sheet.pdf` is the raw `Document` underneath if you want to draw something none of them cover.

A design of your own gets light, dark and tinted for free: the page is painted by `Sheet`, not by the design.

### Sections of your own

The built-in set will always be missing something — patents, exhibitions, press, licences by state. `Section` is open, so add one and put it where it belongs:

```swift
Resume(
    profile: profile,
    experience: roles,
    custom: [
        CustomSection("Patents",
                      body: "Two granted, one pending.",
                      items: ["GB2601234 — Ledger write ordering"])
    ],
    order: [.summary, .experience, .custom("Patents"), .education]
)
```

A block carries prose, a list and dated entries, and renders whichever are filled. One with no place in `order` is not drawn — which is how a section gets left out of this application without being deleted.

### Monospace

`terminal` sets the labels, dates and contact details in JetBrains Mono and the prose in Inter. The mixture is the design and not decoration: dates are read by comparing them down a column, where a monospace lines the digits up, and sentences are read along a line, where nine-point monospaced prose is markedly harder work.

The mono family is available to any design and loaded only when one asks, so the other thirteen do not carry it.

## Fitting the page

```swift
let theme = try resume.fitted(to: 1, design: .ledger)
```

Tries relaxed, then normal, then compact, and stops at the first that fits. Returns `nil` when even the tightest will not — that is a content problem, and what to cut is not a decision a layout engine should make on somebody's behalf.

## Cover letters

A genuinely different document rather than a résumé with prose in it: it is addressed to somebody, it argues rather than lists, and it is read from the top instead of scanned.

```swift
let letter = CoverLetter(
    profile: resume.profile,          // the same person, so the two agree
    recipient: Recipient(name: "Ms Adaeze Okonkwo", organisation: "Northwind Payments"),
    date: "14 August 2026",
    subject: "Re: Staff Infrastructure Engineer (ref. NW-2291)",
    body: ["I am writing about…"],
    highlights: [Highlight("Ledger reliability", "Rebuilt a write path handling £4.2bn a year.")]
)

try letter.save(to: url, design: .panel)
```

| Letter | Pairs with |
|---|---|
| `memo` | `ledger` |
| `letterhead` | `broadsheet` |
| `panel` | `plaque` |
| `monogram` | `bulletin` |

The greeting and the sign-off are derived when they are not given, and they follow the British convention: *faithfully* to a stranger, *sincerely* to a name. It costs nothing to observe and is noticed by exactly the people who observe it.

`letter.check()` reports the things that actually sink a letter — that it is addressed to a job title rather than a person, that it never mentions the employer anywhere but the address block, that it has run past 450 words. The employer check is the useful one: a letter that names the company only in the address block is a template with the name changed, and it reads as one.

## Checking before you send

```swift
let report = try resume.check(design: .ledger, region: .unitedStates)
```

```
pages: 1   clean: true

[warning] "Where I've Worked" is not a heading a parser will recognise.
[warning] "Sep '16" has no four-digit year (Backend Engineer at Deliveroo).
[warning] No skills section.
[warning] Date of birth should not be on a United States résumé.
[note] No phone number.
[note] "References available on request" is taking up a line.
```

Every finding carries a `detail` explaining why it matters, because a warning nobody understands is a warning people turn off.

None of this is a standard. Vendors parse differently and none of them publish how, so these are the failures that are well attested rather than a specification anybody can be measured against. They are also all things the library can actually see: the checks are about the document, not about whether somebody is a good candidate.

### What a heading costs

A tracking system works out which block is the employment history by matching the heading above it. "Where I've Worked" is still read — as prose, filed under nothing, and scored as though the candidate has never had a job. It is the cheapest mistake on this list and among the most expensive.

### Regional particulars

The same four fields, opposite advice, and nobody tells you which side of the line you are on.

| | Date of birth, nationality, marital status |
|---|---|
| US, UK, Canada, Australia | Leave off. An employer may not consider them, and the cheapest way to prove they did not is never to have seen them — so recruiters at larger firms are routinely told to reject a document carrying them unread. |
| Germany | Conventional on a Lebenslauf, though receding since the AGG. |
| International | No opinion. |

Not legal advice. What is checked is whether the document matches the convention, not whether the convention is a good one.

## Typography

Both families are SIL Open Font Licence 1.1 and travel in the package, because a résumé tool whose output looks like a 1998 memo unless you go and find a font is one nobody uses twice.

Static instances, not variable ones. A variable font carries one set of outlines plus the deltas that make a weight; subsetting keeps the outlines and drops the deltas, so every weight would render as regular.

The weight in the repository does not reach the output. Only the faces a design actually draws with are embedded, and only the glyphs they use — a page carrying three weights of Inter costs about 50 KB, not the 2 MB the files came from.

## Dates are strings

`"Mar 2022"`, `"03/2022"`, `"März 2022"` — all correct somewhere, and formatting one properly means knowing a locale's conventions.

The difference from money in an invoice is that the string is then checked. A parser reads dates by pattern, and one it cannot parse becomes an unexplained gap in an employment history:

```swift
DateRange("2023")                  // "2023" — a single date
DateRange.since("Mar 2022")        // "Mar 2022 – Present"
DateRange("Jun 2019", "Feb 2022")  // "Jun 2019 – Feb 2022"
```

An absent end date means there is no second date, **not** that the thing is ongoing. Treating it as ongoing is the obvious shortcut and it is wrong in exactly the case that matters: a project dated 2023 becomes "2023 – Present", claiming something nobody wrote.

## Another language

```swift
Resume(profile: profile, experience: roles, labels: .german)
```

Headings become *Berufserfahrung* and *Ausbildung*, and an open-ended role reads *heute*. The ATS heading check knows to stay quiet — a Lebenslauf saying *Berufserfahrung* is correct, not a mistake.

## Photographs

`Profile.photo` takes a path to a baseline JPEG. `plaque`, `bulletin`, `nocturne` and `sidebar` have somewhere to put one; the rest ignore it, and `check` says which.

Conventional on a Lebenslauf and across much of the résumé world outside the English-speaking part of it — and a liability in the US and UK, where an employer may not consider what a photograph reveals and the cheapest way to prove they did not is never to have seen it. `Region` reports which situation you are in.

## What it cannot do

**No PNG.** JPEG bytes go into a PDF undecoded, which is what makes image support a hundred lines rather than a codec. Converting first is one command: `sips -s format jpeg in.png --out out.jpg`.

**No right-to-left scripts.** Arabic and Hebrew need bidirectional layout and contextual shaping. Being wrong in a language the writer cannot read is worse than declining.

## Fitting one page

```swift
Theme(density: .compact)
```

Tightens leading and section gaps before touching the type size. Dropping to 8pt is the usual fix and it makes a document look desperate; closing the gaps between blocks buys most of the same room and costs far less.

## Requirements

- macOS 14+ / iOS 17+
- Swift 6

## License

MIT — see [LICENSE](LICENSE).

The bundled typefaces are SIL Open Font Licence 1.1; their licences are in `Sources/ResumePDF/Resources/Fonts`.
