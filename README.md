# Swift Resume PDF

Résumés, CVs, cover letters and business cards as PDFs — and as Word documents, plain text and Markdown. Twenty-four designs, every one a JSON file, real typography, and the checks that decide whether the thing gets read.

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
- 🎨 **Twenty-four designs, all JSON** — genuinely different arrangements, each a file in the package you can copy and edit; the eight two-column ones fold to a single column on request
- 🧩 **Designs as JSON** — `Blueprint` and `LetterBlueprint` compose the same parts the built-ins are made of, no recompile
- ✉️ **Cover letters** — four letter designs, each paired with a résumé one
- 🌗 **Light, dark and tinted** — a property of the theme, so every design gets all three
- 🤖 **ATS checks** — column layout, heading names, date formats, ordering, length
- 🎯 **Against the posting** — which of the posting's own terms are not on the page
- 🌍 **Regional conventions** — what a Lebenslauf must carry and a US résumé must not
- 📄 **Multi-page** — footers know the page count, entries do not split from their headings
- 📥 **JSON Resume** — a `resume.json` from jsonresume.org is read as a `Resume`, the whole v1.0.0 schema
- 📝 **Word, plain text and Markdown** — `docx()`, `plainText()`, `markdown()`, for the form that takes nothing else and the box that says "paste your résumé here"
- 📐 **JSON Schemas** — for a résumé, a letter, a design and a theme, kept honest by the tests
- 🔗 **Clickable contacts** — every email and URL is a link, because a recruiter reads from a screen
- 🖼️ **Photographs** — JPEG or PNG, circular, with transparency kept
- ⬌ **Justified prose** — optional, and only where the measure is wide enough to take it
- 🔤 **Any Latin, Greek or Cyrillic name** — subset and embedded, and still selectable afterwards
- 📦 **Two dependencies** — [swift-text-pdf](https://github.com/arraypress/swift-text-pdf) and [swift-text-docx](https://github.com/arraypress/swift-text-docx), which have none
- 🪶 **~50 KB out** — three subset faces and a page of text

## The designs

| Design | For | Parseable |
|---|---|---|
| `ledger` | Single column, ruled sections, sans. The default. | ✅ |
| `broadsheet` | Serif, centred masthead. Academic, legal, formal. | ✅ |
| `timeline` | Dates in a rail down the left edge. | ✅ |
| `margin` | Section names hung in the left margin. Book typography. | ✅ |
| `nocturne` | Light masthead band, the rest of the page reversed. | ✅ |
| `eclipse` | The whole page reversed, the masthead a step darker still. Nocturne without the light band. | ✅ |
| `bulletin` | Headings as tabs, each with a mark. Navigable at a glance. | ✅ |
| `marker` | Headings struck through with a highlighter. Informal. | ✅ |
| `slate` | Twin masthead panels and a tab beside every section. | ✅ |
| `card` | Every entry on a panel of its own. | ✅ |
| `terminal` | A prompt before every heading, monospaced labels and dates, proportional prose. | ✅ |
| `banner` | A near-black masthead band, name reversed out of it. | ✅ |
| `sidebar` | Tinted rail carrying contact and skills. | ❌ |
| `gazette` | Serif two columns behind a hairline. Academic, executive. | ❌ |
| `plain` | Centred name, ruled headings, a scale that gets a first job onto one page. | ✅ |
| `register` | Alternating tinted section bands, labels in the margin. | ✅ |
| `plaqued` | A dipped coloured panel across the top, with a portrait. | ✅ |
| `carded` | Every section on a panel of its own. | ✅ |
| `split` | Wide left column, narrow right, portrait top right. The commonest two-column résumé on the web. | ❌ |
| `wing` | A narrow left column of skills and projects as chips, the name across the top. | ❌ |
| `foyer` | Portrait and contact details in a light left rail, a mark beside every heading. | ❌ |
| `pillar` | A near-black rail down the right with the portrait in it; the name over the main column. | ❌ |
| `flank` | Sidebar with the rail near-black and the name reversed out of it. | ❌ |
| `marquee` | Banner's dark band over two columns. | ❌ |

Every one of them is a JSON file in the package's resources (`Resources/Designs/`), written in the vocabulary below, and `Blueprint.ledger` *is* `ledger` — not a cousin of it — so editing a design is editing its file. The library is a renderer and a vocabulary; the designs are data it reads. `DesignKind.blueprint` hands any of them back.

The eight marked ❌ are laid out in two columns, and a tracking system cannot read two columns. That is not a bug to be fixed later — two columns and machine-readability are the same trade-off seen from either end, and it is measured rather than assumed: PDFKit hands `split`'s side-by-side headings back as one line, `EXPERIENCE` followed by `SUMMARY`. `check` says so rather than leaving it to be discovered.

Every one of them folds to a single column on request, keeping its masthead, headings, colours and portrait and losing only the column:

```swift
try resume.save(to: out, design: Blueprint.split.singleColumn)   // same look, one column, reads in order
```

So the choice is per document, not per design: the two-column page for the person who will open it, the folded one for the form.

## Themes, not templates

Most of what looks like a dozen résumé designs is four arrangements in a dozen colourways. That is an axis of the theme here, so every design gets it:

```swift
Theme(accent: "#1F3A5F")                        // an ink blue
Theme(accent: "#E8A33D", scheme: .dark)         // reversed out
Theme(accent: "#7A4A2B", tint: "#F6F1E8")       // on warm paper
Theme(density: .compact)                        // six more lines per page
Theme(justified: true)                          // flush both edges
Theme.named("navy")                             // a preset, from its file
```

The presets — `plain`, `navy`, `classic`, `american`, `midnight`, `paper` — are JSON files in the package's resources, the way the designs are, and `Theme.named(_:)` reads one by name.

An accent chosen against white is routinely invisible on a dark page, so it is lifted when it comes too close to the background and left alone when it does not. A design that inverts a band gets a palette derived from that band, so bullets, dates and rules inside it stay legible without knowing anything unusual is happening.

## Résumé, CV, or letter

Two documents, not three. A résumé and a CV are the same data under different conventions — length, ordering, and what is included — so both are a `Resume`, and the conventions are parameters:

```swift
Resume(profile: profile, experience: roles, order: .conventional)   // a résumé
Resume(profile: profile, grants: funding, order: .academic)         // a CV
```

`Section.academic` leads with publications and funding; `Section.graduate` leads with the degree. `Region` supplies the rest — a US résumé is one page and carries no date of birth, a Lebenslauf carries one.

A CV has sections a résumé does not, and those are real:

| Section | What it holds |
|---|---|
| `grants` | Funding, with the funder, the amount, the period and whether you led it |
| `teaching` | Courses taught |
| `talks` | Given, invited or otherwise |
| `service` | Reviewing, editorial work, committees |
| `memberships` | Professional bodies |

And three that the résumé builders have taught readers to expect, which a résumé may carry and a CV rarely does:

| Section | What it holds |
|---|---|
| `achievements` | Results worth a line of their own — a title, a sentence, and a mark beside it (`star`, `flag`, `bolt`, `check`, `diamond`, or any section's mark; leave it out and the marks cycle). Two abreast in a wide column, stacked in a narrow one |
| `strengths` | A quality and the sentence that shows it. The same shape, without the mark |
| `time` | How the week goes, as a ring divided in proportion with a lettered legend. Shares are weights, not percentages, so `3, 2, 1` needs no arithmetic |

```json
{
  "achievements": [
    { "title": "Latency halved", "summary": "p99 from 340ms to 45ms.", "icon": "bolt" },
    { "title": "Zero-downtime migration", "summary": "Forty services, one weekend." }
  ],
  "strengths": [ { "title": "Calm under paging", "summary": "Ran the channel for both outages." } ],
  "time": [ { "label": "Building", "share": 40 }, { "label": "Reviewing", "share": 25 }, { "label": "Mentoring", "share": 35 } ]
}
```

All three survive the flat formats: an achievement is a bullet with a bold lead in Word and in text, and the ring becomes a list with percentages — the only honest flat rendering of a picture of proportions. A custom section can be made of achievements too (`{"achievements": [...]}` as a content block), which is what a "Passions" section with marks beside each is.

A language's `level` stays the words somebody wrote — `"Native"`, `"C1"`, `"Conversational"` — and a design may draw them as dots or a bar as well (`"languages": "dots"` in its entries). What the words are worth on a five-point scale is a fixed table (native and C2 are five, fluent and C1 four, intermediate and B1/B2 three, and so on); words the table does not know draw nothing, because the wrong number of dots is a claim the candidate never made.

A cover letter *is* a different document, so it is a different type. See below.

So is a business card, and for the same reason — but it shares the ``Profile``, which is the whole point:

```swift
let card = Card(profile: profile, organisation: "Stripe", title: "Infrastructure Engineer")
try card.save(to: url, design: .plate, bleed: 3)          // 85 × 55 mm, print-ready
```

A card is 85mm wide, so it holds a name, a claim and three ways to reach somebody — and one that tries to say more says none of it. What the printed side does not carry, the code does: it encodes a **vCard** by default, so the phone that scans it saves the contact rather than opening a page and asking somebody to type it in.

| | |
|---|---|
| `plate` | Name, claim and contacts on the front; the code on a dark back |
| `reverse` | A reversed front carrying the name alone; the rest on a light back |
| `portrait` | A photograph beside the name |
| `minimal` | A centred name, and everything else on the back |

`title` is given separately from the profile's headline because a résumé's headline is written to be read at leisure — "Senior Project Manager | Treasury & Expense Management" — and a card has 85mm. Leave it out and the headline is used.

**Bleed.** `bleed: 3` is what a printer asks for, in millimetres: the artwork runs that far past the trim with crop marks in it, so a guillotine a hair out of true still cuts through ink rather than leaving a white line. The marks are drawn in the bleed and stop short of the trim, so none is left on the finished card; below about 1.5mm there is no room for both and they are left off rather than printed onto it. Leave it at zero for a card that will only be looked at on a screen.

A card design is data too, in the same way a résumé design is — two sides, a fill each, and an ordered list of what sits on them:

```json
{
  "name": "mine",
  "front": { "fill": "page", "align": "left", "content": ["name", "title", "rule", "contacts"] },
  "back":  { "fill": "ink", "align": "centre", "content": ["code"] }
}
```

The elements are `name`, `title`, `organisation`, `contacts`, `code`, `tagline`, `portrait`, `rule` and `space`. One with nothing to show — a code on a card with no payload, a portrait on a profile with no photograph — is skipped rather than left as a gap, so one design serves a profile that carries a face and one that does not.

## Building your own

Two ways: describe one as JSON, or write one in Swift. The first covers the range the built-ins cover; the second covers anything.

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

A theme that names a face wins; one that names none takes the design's own — which is how `broadsheet` gets its serif without being asked.

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

### A design written as JSON

A design does not have to be Swift. The single-column designs are all the same skeleton — masthead, then heading + entries + gap per section, then footer — and what separates them is a bounded set of choices about it. That vocabulary is a `Blueprint`, and a blueprint is data:

```json
{
  "name": "ember",
  "masthead": { "nameSize": 31, "uppercase": true, "tracking": 1.2 },
  "heading": { "style": "marker", "colour": "#B00020" },
  "entries": { "skills": "chips", "entryGap": 15 },
  "ornament": "bands"
}
```

```swift
let mine = try Blueprint(contentsOf: url)
try resume.save(to: out, design: mine)
```

Name only what you want changed — everything else takes the default, so two keys is a design. `Blueprint.starting` holds the twenty-four designs, because nobody writes one from an empty file and the best place to start is one that already works. `plain` is the one for a first job — centred name, ruled headings, nothing else, at a scale that keeps it to the page a US posting expects.

| Key | What it sets |
|---|---|
| `typeface` | `sans` or `serif` — a design whose identity is a serif can say so |
| `masthead` | align, nameSize, nameWeight, nameColour, uppercase, tracking, headline (size, colour, italic), contacts (`flow` or `labelled`), separator, `panel`, `photo`, `qr`, `rule` (colour, thickness, `double`, `width`, `underName`), `monospaced`, `twin` panels, a painted `body` and `band` |
| `column` | full width, or inset with labels hung in the margin; `headAtMargin` keeps the head and headings at the page edge; `ruled` draws a hairline above every section |
| `heading` | `ruled`, `plain`, `accentBar`, `centred`, `tab`, `marker`, `margin`, `terminal`, `underlined` — size, colour, icon |
| `entries` | date placement, four sizes, entry gap, accent roles, `list`/`chips`/`bars`/`dots`/`underlined`/`inline` skills, `text`/`dots`/`bars` language levels |
| `ornament` | `none`, `bands`, `cards`, `entryCards`, `rail`, `tabs` |
| `side` | a second column: `edge`, `width`, the `sections` it carries, a `fill` (`rail`, `ink`, a hex — a dark one gets reversed type), `divider`, and where the `head` goes: `inside` the column, `above` both, or `main` — the name over the main column, the portrait and contact details at the head of the side |
| `side` | a second column: width, edge, the sections it carries, a `rail` fill or a hairline divider, the masthead inside it or above both |
| `sections` | any of the above, for one section only |
| `palette` | theme colours this design overrides |

A section can be set differently from the rest, which is a decision the built-in designs make and a format that could not express it would stop one step short:

```json
{ "entries": { "skills": "list", "roleSize": 11 },
  "sections": {
    "skills": { "entries": { "skills": "chips" }, "sectionGap": 22 },
    "summary": { "heading": { "style": "plain" } }
  } }
```

An override changes only what it names — the 11pt roles above survive into the skills section, because a patch of defaults would quietly undo the design.

Colours are named (`accent`, `ink`, `muted`, `wash`, `hairline`, `page`, and `rail`, `inverse`, `dark`, `darkest` for a tinted column or a painted body) or given as hex. Named ones follow the theme, so a blueprint works under whatever accent somebody sets rather than pinning one into it.

Nothing the designs do is outside this vocabulary, because the designs *are* this data — including the two-column pair. A `side` is the one key that produces a page a parser reads wrong, and a blueprint that has one is reported by `check` exactly as `sidebar` and `gazette` are.

**There is no layout language here** — no boxes, no coordinates, no expressions. A general one lets somebody build a résumé that overlaps itself, and its failure mode is a document that renders looking wrong rather than an error saying what is wrong. Composition of known-good parts fails differently: every combination of these choices produces a page that reads. The one that a tracking system reads wrong — a `side` column — is not hidden from the format; it is the thing `check` exists to name. That is what makes the format safe to hand somebody: not that it cannot say the wrong thing, but that everything it says is checked.

A blueprint is checked exactly like a compiled design — `check(design:)` takes any `Design` — because an extension point that skips the checks is a hole in them.

### A letter design written as JSON

Letters take the same treatment, with a smaller vocabulary — because `LetterLayout` asks for the masthead and nothing else:

```json
{
  "name": "ember-letter",
  "pairsWith": "marker",
  "masthead": {
    "align": "centre", "nameSize": 26, "uppercase": true, "tracking": 1.4,
    "contacts": "flow", "finish": "capped"
  }
}
```

`contacts` is `flow`, `ranged` (stacked against the name, the way printed stationery sets it), `panel` (in a filled box, each with its mark) or `none`. `finish` is `rule`, `capped` (a short rule with a mark at each end) or `none`.

**The body is not yours to move.** Recipient, greeting, argument, sign-off are set the same way by every design, built-in or written. That is not an omission: the shape of a letter is older and less negotiable than a résumé's, and rearranging those parts does not make it look modern — it makes it look like it was written by somebody who has not read one.

`pairsWith` names the résumé design it sits beside, which is what a tool reads to set both halves of an application in the same face. The four letter designs are themselves files in `Resources/Letters/`, the way the résumé designs are in `Resources/Designs/`.

### Sections of your own

The built-in set will always be missing something — patents, exhibitions, press, licences by state. `Section` is open, so add one and put it where it belongs:

```swift
Resume(
    profile: profile,
    experience: roles,
    custom: [
        CustomSection("Patents", [
            .prose("Two granted, one pending."),
            .list(["GB2601234 — Ledger write ordering"])
        ])
    ],
    order: [.summary, .experience, .custom("Patents"), .education]
)
```

A block carries prose, a list and dated entries, and renders whichever are filled. One with no place in `order` is not drawn — which is how a section gets left out of this application without being deleted.

In JSON each block is named by its kind, so a section of your own is as writable as the built-in ones:

```json
{ "custom": [
    { "title": "Patents",
      "content": [
        { "prose": "Two granted, one pending." },
        { "list": ["GB2601234 — Ledger write ordering"] },
        { "positions": [{ "role": "Named inventor", "organisation": "Stripe" }] }
      ] }
  ],
  "order": ["summary", "experience", "custom:Patents", "education"] }
```

Eleven kinds: `prose`, `list`, `positions`, `education`, `projects`, `publications`, `credentials`, `awards`, `grants`, `skills`, `languages`. A block naming two of them, or none, is an error rather than a guess.

### Monospace

`terminal` sets the labels, dates and contact details in JetBrains Mono and the prose in Inter. The mixture is the design and not decoration: dates are read by comparing them down a column, where a monospace lines the digits up, and sentences are read along a line, where nine-point monospaced prose is markedly harder work.

The identity comes from the chrome. Every heading is preceded by a prompt — drawn as two strokes rather than typed, so the word a parser matches on is still the word — and the contact details run along one mono line with a pipe between them, the way a shell prints a status line.

The mono family is available to any design and loaded only when one asks, so the other thirteen do not carry it.

## Fitting the page

```swift
let theme = try resume.fitted(to: 1, design: .ledger)
```

Tries relaxed, then normal, then compact, and stops at the first that fits. Returns `nil` when even the tightest will not — that is a content problem, and what to cut is not a decision a layout engine should make on somebody's behalf.

### Justified prose

Off by default, and applied only where there is room: below about forty characters of measure the gaps grow until they line up into rivers down the column, so a narrow rail stays ragged whatever the theme says.

It is set a word at a time rather than with the `Tw` operator, because `Tw` adds its space to byte 32 and under Identity-H — how every embedded font here is encoded — byte 32 is half of a two-byte character code. A résumé set that way would come out with gaps inside its words.

Costing nothing in extraction is the part that matters, and there is a test for it: the sentence still comes back out of the file as a sentence, with no doubled spaces for a keyword search to fall into.

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
| `panel` | `banner` |
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

### Against the posting

```swift
let posting = try Posting(contentsOf: postingURL)
let report = try resume.check(design: .ledger, posting: posting)
report.coverage?.missing      // ["Terraform", "Datadog", "ArgoCD"]
```

The other half of what a tracking system does. Once it has the text, it scores it against the posting — and the crude form of that score, which is the form most of them use, is whether the posting's words appear at all. Kubernetes in the posting and "container orchestration" on the page is a miss, however true the page is.

`Posting` reads an advertisement the way that scorer would. The terms are the hard-edged tokens — the things with capitals, digits, dots and slashes in them: `C++`, `Node.js`, `CI/CD`, `ES6`, `AWS`, `PostgreSQL` — and the proper nouns that sit in lists beside them. The prose around them is not: a company's name and a city live in sentences, and technologies live in bullets. Matching forgives case, a plural, and the spelling variants a scorer forgives — `Node.js`, `NodeJS` and `node js` are one word.

The result is a warning naming what is absent, not a blocker: the document is still read, it just scores lower. What to add is a question of what is true, which no check can answer. `report.coverage` carries the found and missing lists and the ratio.

It is a heuristic and says so. A customer named in a bullet will be read as a requirement now and then, and a technology that opens a sentence in prose will be missed — because an employer's name sits in exactly that place, and the two cannot be told apart. The alternative, a dictionary of every technology, would be out of date the week it shipped.

### What a heading costs

A tracking system works out which block is the employment history by matching the heading above it. "Where I've Worked" is still read — as prose, filed under nothing, and scored as though the candidate has never had a job. It is the cheapest mistake on this list and among the most expensive.

### Regional particulars

The same four fields, opposite advice, and nobody tells you which side of the line you are on.

| Where you are applying | Date of birth, nationality, marital status |
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

## Written as JSON

Every type is `Codable`, and the JSON asks only for what identifies a thing:

```json
{
  "profile": { "name": "Alex Moreau", "email": "alex@moreau.dev" },
  "experience": [
    { "role": "Senior Infrastructure Engineer",
      "organisation": "Stripe",
      "dates": { "start": "Mar 2022", "end": "Present" },
      "highlights": ["Took p99 commit latency from 340ms to 45ms."] }
  ]
}
```

A position needs a `role`, an education a `qualification`, a project a `name` — everything else defaults exactly as the Swift initialiser does. This does not come free: Swift's synthesised decoder ignores a property's default, so a type you can build in one line still demands every key in JSON unless the decoders are written out. They are.

Three shorthands, for the things written most often:

```json
"dates": "2023"                      "dates": { "start": "2023", "end": "" }
"links": ["https://github.com/x"]    [{ "url": "…", "label": "github.com/x" }]
"labels": "de"                        the whole German label set
```

What is *not* defaulted is the identifying field. A position with no role is not a position, and accepting one would turn a mistyped key into a blank line on somebody's résumé.

## Reading a JSON Resume

```swift
let resume = try Resume(jsonResumeData: try Data(contentsOf: url))   // a resume.json from jsonresume.org
```

Thousands of people already have a `resume.json` in the [JSON Resume](https://jsonresume.org/schema) schema, and a tool that made them retype it would not be used. `JSONResume` decodes the whole v1.0.0 schema — every property, checked against the schema in the tests — and `Resume(jsonResume:)` maps it. `JSONResume.looksLikeOne(data)` tells the two shapes apart, so a tool can read either from the same flag.

The mapping is one-way and lossy in a few named places, each of them a decision rather than an omission:

| Schema | Here |
|---|---|
| `basics.location.address`, `postalCode` | Not printed. A street address is not wanted on a résumé and never was; the city and region are kept. |
| `work[].description` | Joins the position's summary. |
| `work[].url`, `volunteer[].url`, `education[].url`, `certificates[].url` | Not printed. An entry carries no link of its own; the links on a résumé are the person's. `projects[].url` and `publications[].url` are kept, because those *are* the work. |
| `education[].courses` | The entry's highlights. |
| `skills[].level` | Not printed. A word ("Master") rather than a number, and a printed proficiency label is the thing recruiters most distrust. |
| `projects[].entity` | Rides on the role line. `projects[].type` is not printed. |
| `publications[].summary` | Not printed; there is no equivalent. |
| `interests[].keywords` | In brackets after the interest. |
| `references[]` | Each quote, then its name. |
| `meta`, `$schema` | Read, not printed. About the file, not the person. |

Dates come through as a résumé prints them: `2022-03-15` is `Mar 2022`, `2022` stays `2022`, and a job with no `endDate` is current. The old `company` spelling of a work entry's `name` is read, because files in the wild were written against three versions of the schema and by hand.

## A code to scan

```swift
Profile(name: "Alex Moreau", email: "alex@moreau.dev", qr: "https://moreau.dev/cv")
```

Worth the square inch on a printed CV, where a link is a thing to be typed by hand and therefore not followed. `ledger` and `terminal` place one; the rest ignore it, and `check` says which. In a blueprint it is `"masthead": { "qr": 58 }`.

Drawn as vector squares in the ink colour, because a scanner wants contrast and a pale brand colour on white is a code that reads on a screen and fails on a photocopy.

**It is not a substitute for the address in writing.** A parser reads text; a code is a picture. `check` reports it when the code is the only place an address appears — a URL no tracking system will ever see is a URL you did not publish.

## As a Word document, as text, as Markdown

```swift
try resume.saveDocx(to: url)                          // one layout, the theme's face and colour
let data = resume.docx(theme: Theme(accent: "#1F3A5F"))
let pasted = resume.plainText()                       // for the box that says "paste your résumé here"
let readme = resume.markdown()
try letter.saveDocx(to: letterURL)                    // the letter too
```

The commonest way a résumé reaches a tracking system is not a file at all: it is pasted into a form. `plainText()` is that paste — single column, the headings in capitals, a dash before every bullet, and nothing wrapped, because a form reflows its own text and a hard break inside a sentence is what makes a pasted résumé look pasted. `markdown()` is the same walk with the emphasis kept.

All three come from one outline of the document — `resume.outline()`, public, a list of `Outline.Block`s — so a section the PDF carries is in every flat format or in none, and a format this library does not write is a short renderer over the same blocks rather than a second walk over the model.

For the form that takes nothing else. One layout, not twenty-four: the name at the top, headings Word recognises as headings, real bullets, a date against the right margin on the same line as the title — the document a parser reads correctly, and nothing that would confuse one. Every section the PDF carries is written, in the résumé's own order, under the same labels, in the theme's typeface and colour. What is not carried is the photograph and the code: a form that wants a `.docx` wants neither.

Written by [swift-text-docx](https://github.com/arraypress/swift-text-docx), which is to Word what swift-text-pdf is to PDF: a direct writer, no dependencies, the same bytes for the same document. `docxDocument(theme:)` returns the document before it is written, for a caller who wants to add to it.

The tests hand the file to `textutil`, the system's own reader, and check the words come back in the order they went in.

## The schemas

```swift
let schema = Schema.resume.json                       // JSON Schema, draft 2020-12
```

Everything the library reads is JSON, and an editor or an agent that has the schema stops guessing the keys. There is one each for a résumé (`Schema.resume`, including the `design`, `theme` and `extends` keys a tool reads beside it), a letter, a design (`.blueprint`), a letter design and a theme. They are kept honest by the tests, which validate every design, letter and theme the package carries — and the sample documents — against them.

## Archival copies

```swift
try resume.render(design: .ledger, archival: true)   // PDF/A-3
```

Some academic and government applications ask for one by name. Free here: PDF/A requires every font to travel with the document, which these already do.

The one thing that can break the claim is a run of text no bundled face covers, which falls back to a font the reader supplies. Asked for `archival:` anyway, the render throws `ResumeError.notArchival` — naming the runs — rather than writing a file that claims a standard it fails.

## Photographs

`Profile.photo` takes a path to a baseline JPEG or a PNG. `bulletin`, `nocturne`, `eclipse`, `banner`, `plaqued`, `sidebar`, `split`, `foyer`, `pillar` and `marquee` have somewhere to put one; the rest ignore it, and `check` says which.

A PNG's transparency is kept — it becomes a soft mask rather than being flattened onto white, so a cut-out portrait does not arrive on a square. A missing or unreadable file leaves a gap rather than failing the render: a résumé that refuses to build because a photograph moved is worse than one with a space where a face was. `check` says why — a file that cannot be read, a progressive JPEG, or an EXIF rotation the writer will not apply, which prints a phone portrait on its side.

Conventional on a Lebenslauf and across much of the résumé world outside the English-speaking part of it — and a liability in the US and UK, where an employer may not consider what a photograph reveals and the cheapest way to prove they did not is never to have seen it. `Region` reports which situation you are in.

## What it cannot do

**No right-to-left scripts.** Arabic and Hebrew need bidirectional reordering and contextual shaping — a letter changes form by its position in a word.

The shaping is not the obstacle; CoreText would supply reordered, shaped glyphs. The obstacle is that this engine believes text is *strings you can measure* — wrapping, truncation, tracking and justification all assume you can measure a string and cut it at a character. Shaped runs are glyphs with positions, where a character may be half a ligature and the visual order is not the logical one. And an Arabic résumé needs a mirrored *page*, not only mirrored text.

So it is refused rather than half-built. Correct Arabic text in a left-to-right layout is still a document nobody can send.

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
