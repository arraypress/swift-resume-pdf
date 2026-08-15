# Swift Resume PDF

Résumés and CVs as PDFs. Four designs, real typography, and the checks that decide whether the thing gets read.

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

- ✒️ **Real typography** — Inter and Source Serif 4 travel with the package, in several weights and italic
- 🎨 **Four designs** — genuinely different arrangements, not one with the colours changed
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
| `sidebar` | Tinted rail carrying contact and skills. | ❌ |

`sidebar` is the best-looking of the four and the only one a tracking system cannot read. That is not a bug to be fixed later — two columns and machine-readability are the same trade-off seen from either end. Send it where a person will open it, and use one of the others for anything that goes through a form. `check` says so rather than leaving it to be discovered.

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

## What it cannot do

**No photographs.** The writer draws text and vector shapes and has no image support, so a Lebenslauf or a French CV that wants one has to have it added afterwards. `check` says so when the region expects it, rather than producing a document that is quietly wrong for where it is going.

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
