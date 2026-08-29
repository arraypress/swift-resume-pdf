//
//  Posting.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The other half of what a tracking system does.
//
//  ``ATS`` answers "will the text come out in order?". A parser that has
//  the text then scores it against the posting — and the crude form of that
//  score, which is the form most of them use, is whether the words the
//  posting names appear at all. Kubernetes in the posting and "container
//  orchestration" on the résumé is a miss, however true the résumé is.
//
//  This reads the posting the way that scorer would. The terms are the
//  hard-edged tokens — the things with capitals, digits, dots and slashes
//  in them — and the proper nouns that sit in lists beside them; the prose
//  around them is not. It is a heuristic and says so. The alternative, a
//  dictionary of every technology, would be out of date the week it
//  shipped, and would still not know the name of the customer's product.
//
//  What it knowingly gets wrong: a technology that opens a sentence in
//  prose ("Kafka is at the heart of…") is read as the sentence's subject and
//  left out, because a company's name sits in exactly that place and the
//  two cannot be told apart. Lists keep both, and postings put their
//  requirements in lists.
//

import Foundation

/// A job posting, reduced to the terms a scorer would look for.
public struct Posting: Sendable, Equatable {

    public let text: String

    /// The terms, in the order they first appear, each once.
    public let terms: [String]

    public init(_ text: String) {
        self.text = text
        self.terms = Posting.terms(in: text)
    }

    public init(contentsOf url: URL) throws {
        self.init(try String(contentsOf: url, encoding: .utf8))
    }

    // MARK: Reading the posting

    /// One word of a line, with what surrounded it.
    private struct Token {
        let text: String
        /// First on the line, or after a full stop, colon or the like.
        let startsSentence: Bool
        /// Nothing but a space between this and the next — so the two may
        /// be one name, as "GitHub Actions" is.
        let joinsNext: Bool
    }

    /// The terms in some text, in order of first appearance.
    ///
    /// A token is a term when it is *hard* — carries a digit, an internal
    /// dot or slash, a `+` or `#`, is an acronym, or has a capital inside it
    /// — or when it is a capitalised word that is not opening a sentence,
    /// not an everyday word, and sits on a line that is a bullet or already
    /// holds a hard term. That last condition is what keeps the employer's
    /// name and the city out of the list: they live in prose, and the
    /// technologies live in lists.
    public static func terms(in text: String) -> [String] {
        var found: [String] = []
        var seen: Set<String> = []

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let bulleted = line.first.map { bullets.contains($0) } ?? false
            let words = tokens(in: line, bulleted: bulleted)
            // A bullet is a list. Prose is a list only when two hard tokens
            // say so — one is "trusted by OpenAI, PayPal and Ramp", and those
            // are customers, not requirements.
            let listContext = bulleted || words.filter { isHard($0.text) }.count >= 2

            var index = 0
            while index < words.count {
                let word = words[index]
                let qualifies = isHard(word.text)
                    || (listContext && isProperNoun(word.text) && !word.startsSentence)
                guard qualifies else { index += 1; continue }

                var term = word.text
                var next = index + 1

                // "GitHub Actions", "Google Cloud Platform": capitalised
                // words run together into one name, up to three of them.
                while next < words.count, next - index < 3, words[next - 1].joinsNext,
                      isCapitalised(words[next].text),
                      isHard(words[next].text) || !isEveryday(words[next].text)
                          || nameContinuers.contains(words[next].text.lowercased()) {
                    term += " " + words[next].text
                    next += 1
                }

                // "SOC 2", "Web 3": a short number riding on the term.
                if next < words.count, words[next - 1].joinsNext,
                   words[next].text.count <= 2, words[next].text.allSatisfy(\.isNumber) {
                    term += " " + words[next].text
                    next += 1
                }

                if seen.insert(term.lowercased()).inserted { found.append(term) }
                index = next
            }
        }
        return found
    }

    private static let bullets: Set<Character> = ["•", "-", "*", "–", "·", "▪", "◦", "‣"]
    static let leading: Set<Character> = [
        "(", "[", "{", "\"", "'", "“", "‘", "•", "-", "*", "–", "·", "▪", "◦", "‣", "$", "€", "£",
    ]
    static let trailing: Set<Character> = [")", "]", "}", "\"", "'", "”", "’", ",", ";", ":", ".", "!", "?"]

    /// A semicolon is not here: in a posting it separates list items, and
    /// "AWS; Postgres or MySQL" does not start a sentence at Postgres.
    private static let sentenceEnders: Set<Character> = [".", "!", "?", ":"]

    private static func tokens(in line: String, bulleted: Bool) -> [Token] {
        let pieces = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        var tokens: [Token] = []
        var nextStartsSentence = true

        for (position, piece) in pieces.enumerated() {
            var text = Substring(piece)
            while let first = text.first, leading.contains(first) { text.removeFirst() }
            // "Vercel's" is Vercel.
            for possessive in ["'s", "’s"] where text.hasSuffix(possessive) { text.removeLast(2) }
            var endedSentence = false
            var punctuated = false
            while let last = text.last, trailing.contains(last) {
                if sentenceEnders.contains(last) { endedSentence = true }
                punctuated = true
                text.removeLast()
            }
            guard !text.isEmpty else {
                // A lone dash or bullet: what follows still opens the line.
                if position == 0 { continue }
                nextStartsSentence = nextStartsSentence || endedSentence
                continue
            }

            tokens.append(Token(text: String(text), startsSentence: nextStartsSentence,
                                joinsNext: !punctuated))
            nextStartsSentence = endedSentence
        }

        // A bullet is not a sentence. "Kubernetes, Terraform and AWS" and
        // "Kubernetes in production" both open with the term, and the words
        // a bullet opens with when it *is* a sentence — Build, Own, Ensure,
        // Experience — are everyday ones, and filtered as such.
        if bulleted, !tokens.isEmpty {
            tokens[0] = Token(text: tokens[0].text, startsSentence: false, joinsNext: tokens[0].joinsNext)
        }
        return tokens
    }

    // MARK: What counts

    /// A token with an edge to it: `C++`, `Node.js`, `CI/CD`, `ES6`, `AWS`,
    /// `PostgreSQL`.
    static func isHard(_ token: String) -> Bool {
        guard token.count >= 2, token.contains(where: \.isLetter), !token.contains("(") else { return false }
        let letters = token.filter(\.isLetter)
        let hasUpper = letters.contains(where: \.isUppercase)
        let hasLower = letters.contains(where: \.isLowercase)
        let hasDigit = token.contains(where: \.isNumber)

        // "180K", "10M", "5%": a quantity, whatever letter rides on it.
        let quantity = token.filter { !"KMBkmb%+".contains($0) }
        if !quantity.isEmpty, quantity.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) {
            return false
        }

        if token.contains("+") || token.contains("#") { return true }
        if hasDigit { return true }
        if token.contains("/") { return hasUpper || hasDigit }
        if token.contains(".") {
            if hasUpper { return true }
            let suffix = token.split(separator: ".").last.map(String.init) ?? ""
            return dottedSuffixes.contains(suffix.lowercased())
        }
        if hasUpper, !hasLower {
            return letters.count <= 8 && !everydayAcronyms.contains(token.uppercased())
        }
        if hasUpper, hasLower {
            // "APIs", "RSUs": an acronym in the plural is still the acronym.
            if token.hasSuffix("s"), token.dropLast().allSatisfy({ $0.isUppercase || $0 == "-" }) {
                return letters.count <= 9
                    && !everydayAcronyms.contains(String(token.dropLast()).uppercased())
            }
            // A capital after the first letter: PostgreSQL, GraphQL, iOS, jQuery.
            return token.dropFirst().contains(where: \.isUppercase) && !everydayMixed.contains(token)
        }
        return false
    }

    /// `Kubernetes`, `Terraform`: capitalised, and not a word anybody would
    /// capitalise for another reason.
    static func isProperNoun(_ token: String) -> Bool {
        isCapitalised(token) && !isEveryday(token)
    }

    static func isCapitalised(_ token: String) -> Bool {
        guard let first = token.first, first.isUppercase, token.count >= 2 else { return false }
        return token.dropFirst().allSatisfy { $0.isLowercase || $0 == "-" || $0 == "'" || $0 == "’" }
    }

    static func isEveryday(_ token: String) -> Bool {
        let lowered = token.lowercased()
        return everydayWords.contains(lowered) || places.contains(lowered)
    }

    /// Where the job is, which is not what the job needs.
    private static let places: Set<String> = [
        "london", "manchester", "birmingham", "edinburgh", "glasgow", "dublin", "bristol", "leeds",
        "cambridge", "oxford", "berlin", "munich", "hamburg", "paris", "lyon", "amsterdam",
        "rotterdam", "brussels", "zurich", "geneva", "vienna", "stockholm", "oslo", "copenhagen",
        "helsinki", "madrid", "barcelona", "lisbon", "milan", "rome", "warsaw", "prague", "budapest",
        "athens", "istanbul", "tel", "aviv", "dubai", "singapore", "tokyo", "osaka", "seoul", "sydney",
        "melbourne", "auckland", "toronto", "vancouver", "montreal", "ottawa", "new", "york", "san",
        "francisco", "jose", "diego", "los", "angeles", "seattle", "portland", "austin", "dallas",
        "houston", "chicago", "boston", "denver", "atlanta", "miami", "philadelphia", "washington",
        "phoenix", "minneapolis", "detroit", "raleigh", "nashville", "salt", "lake", "city", "bay",
        "area", "silicon", "valley", "england", "scotland", "wales", "ireland", "britain", "europe",
        "america", "canada", "australia", "germany", "france", "spain", "italy", "netherlands",
        "switzerland", "sweden", "norway", "denmark", "finland", "poland", "india", "japan", "china",
        "brazil", "mexico", "emea", "apac", "latam", "north", "south", "east", "west", "central",
        "ny", "ca", "tx", "wa", "ma", "il", "co", "ga", "fl", "nc", "or", "pa", "va", "md", "dc",
    ]

    private static let dottedSuffixes: Set<String> = ["js", "ts", "net", "io", "py", "rs", "sh", "css", "ai", "dev"]

    /// Everyday words that are part of a product's name when they follow one
    /// with a capital: Google *Cloud*, Visual Studio *Code*, GitHub *Actions*.
    private static let nameContinuers: Set<String> = [
        "cloud", "platform", "studio", "code", "actions", "services", "service", "web", "server",
        "maps", "analytics", "functions", "engine", "data", "suite", "office", "native", "foundation",
        "framework", "search", "ads", "sheets", "docs", "drive", "workspace", "enterprise", "manager",
        "designer", "builder", "central", "connect", "hub", "pro", "core", "labs", "flow", "learning",
    ]

    /// Acronyms a posting uses for reasons other than a skill.
    private static let everydayAcronyms: Set<String> = [
        "A", "AN", "AND", "OR", "THE", "OF", "TO", "IN", "ON", "AT", "BY", "FOR", "WITH", "IS", "ARE",
        "BE", "AS", "IF", "NOT", "NO", "YES", "ALL", "ANY", "NEW", "US", "USA", "UK", "EU", "UAE",
        "NYC", "LA", "SF", "DC", "ET", "PT", "CT", "MT", "CET", "GMT", "UTC", "BST", "AM", "PM",
        "HR", "IT", "CEO", "CTO", "CFO", "COO", "CIO", "VP", "SVP", "EVP", "PTO", "EEO", "EOE",
        "ADA", "GPA", "BS", "BA", "MS", "MA", "MBA", "ASAP", "FAQ", "ID", "OK", "LLC", "INC", "LTD",
        "PLC", "GMBH", "CO", "USD", "EUR", "GBP", "CAD", "AUD", "RSU", "ESPP", "K", "M", "B",
        "LGBTQ", "LGBTQIA", "DEI", "HQ", "EST", "PST", "TBD", "TBC", "NB", "FYI", "PS", "ETC", "EG",
        "IE", "FTE", "OTE", "YOE", "PA", "PW", "PD", "NA", "TL", "DR", "TBA", "MSC", "BSC", "PHD",
        "API", "APIS", "UI", "UX", "QA", "SLA", "SLAS", "KPI", "KPIS", "OKR", "OKRS", "ROI", "DX", "WFH",
        // US states, which a posting gives after a city
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS",
        "KY", "MD", "MI", "MN", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK",
        "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    ]

    private static let everydayMixed: Set<String> = ["LinkedIn", "PhD", "MSc", "BSc", "iPhone", "McKinsey"]

    /// Capitalised words a posting uses that are not the names of anything.
    private static let everydayWords: Set<String> = [
        // Function words and pronouns
        "a", "an", "the", "and", "or", "but", "nor", "so", "yet", "of", "to", "in", "on", "at", "by",
        "for", "with", "from", "into", "onto", "over", "under", "about", "across", "after", "before",
        "between", "through", "during", "within", "without", "as", "if", "than", "then", "that",
        "this", "these", "those", "it", "its", "is", "are", "was", "were", "be", "been", "being",
        "have", "has", "had", "do", "does", "did", "will", "would", "shall", "should", "can", "could",
        "may", "might", "must", "not", "no", "yes", "all", "any", "some", "each", "every", "other",
        "more", "most", "less", "least", "both", "either", "neither", "such", "same", "own", "i",
        "we", "you", "he", "she", "they", "me", "us", "him", "her", "them", "my", "our", "your",
        "his", "their", "who", "whom", "whose", "which", "what", "where", "when", "why", "how",
        "there", "here", "also", "very", "just", "only", "even", "still", "already", "always",
        "never", "often", "sometimes", "please", "note", "thank", "thanks", "hello", "hi", "dear",
        // Time
        "january", "february", "march", "april", "may", "june", "july", "august", "september",
        "october", "november", "december", "monday", "tuesday", "wednesday", "thursday", "friday",
        "saturday", "sunday", "today", "tomorrow", "yesterday", "week", "weeks", "day", "days",
        "month", "months", "year", "years", "hour", "hours", "quarter", "annual", "daily", "weekly",
        // The job-ad vocabulary
        "job", "role", "roles", "position", "positions", "title", "description", "overview",
        "about", "summary", "responsibilities", "requirements", "qualifications", "duties",
        "skills", "skill", "experience", "experienced", "expertise", "knowledge", "understanding",
        "familiarity", "familiar", "proficiency", "proficient", "ability", "abilities", "background",
        "strong", "solid", "excellent", "good", "great", "proven", "demonstrated", "deep", "broad",
        "hands-on", "working", "practical", "relevant", "required", "preferred", "desired", "plus",
        "bonus", "nice", "ideal", "ideally", "minimum", "maximum", "senior", "junior", "mid",
        "lead", "leads", "principal", "staff", "head", "chief", "director", "manager", "managers",
        "engineer", "engineers", "engineering", "developer", "developers", "development",
        "designer", "designers", "design", "analyst", "analysts", "architect", "architects",
        "scientist", "scientists", "consultant", "consultants", "specialist", "specialists",
        "associate", "associates", "intern", "interns", "internship", "graduate", "apprentice",
        "team", "teams", "company", "companies", "organisation", "organization", "business",
        "customer", "customers", "client", "clients", "user", "users", "people", "person",
        "candidate", "candidates", "applicant", "applicants", "employee", "employees", "employer",
        "colleagues", "stakeholders", "partners", "product", "products", "project", "projects",
        "service", "services", "solution", "solutions", "platform", "platforms", "system",
        "systems", "software", "hardware", "technology", "technologies", "technical", "tools",
        "tool", "data", "information", "quality", "performance", "security", "infrastructure",
        "operations", "support", "sales", "marketing", "finance", "legal", "talent", "recruiting",
        "location", "remote", "hybrid", "office", "onsite", "on-site", "full-time", "part-time",
        "full", "part", "time", "contract", "permanent", "temporary", "salary", "compensation",
        "benefits", "equity", "pension", "health", "dental", "vision", "insurance",
        "holiday", "vacation", "leave", "equal", "opportunity", "opportunities", "diversity",
        "inclusion", "inclusive", "mission", "values", "culture", "growth", "career", "careers",
        "apply", "application", "applications", "interview", "interviews", "process", "hiring",
        "join", "joining", "work", "works", "environment", "world", "global", "local",
        "national", "international", "bachelor", "bachelor's", "bachelors", "master", "master's",
        "masters", "degree", "degrees", "university", "college", "school", "computer", "science",
        "mathematics", "physics", "statistics", "equivalent", "field", "related", "discipline",
        "communication", "collaboration", "collaborative", "leadership", "ownership", "mindset",
        "attention", "detail", "problem", "problems", "solving", "results", "impact", "scale",
        "high", "low", "large", "small", "fast", "modern", "best", "practices", "practice",
        "agile", "cross-functional", "end-to-end", "self-starter", "startup", "start-up",
        "responsible", "responsibility", "including", "include", "includes", "using", "use",
        "build", "building", "builds", "develop", "developing", "maintain", "maintaining",
        "deliver", "delivering", "delivery", "drive", "driving", "help", "helping",
        "ensure", "ensuring", "improve", "improving", "manage", "managing", "management",
        "monitor", "monitoring", "review", "reviews", "code", "coding", "programming",
        "language", "languages", "framework", "frameworks", "library", "libraries", "database",
        "databases", "cloud", "web", "mobile", "backend", "back-end", "frontend", "front-end",
        "fullstack", "full-stack", "devops", "testing", "test", "tests", "automation",
        "deployment", "production", "reliability", "availability", "scalability", "distributed",
        "microservices", "architecture", "api", "apis", "pipeline", "pipelines", "ci", "cd",
        "version", "control", "open", "source", "learning", "machine", "artificial", "intelligence",
        "analytics", "reporting", "dashboard", "dashboards", "documentation", "written", "verbal",
        "english", "fluent", "fluency", "native", "level", "levels", "years'", "e.g", "i.e",
        // Benefits and boilerplate
        "healthcare", "package", "packages", "flexible", "flexibility", "grow", "off", "wfh", "paid",
        "unlimited", "parental", "wellness", "stipend", "budget", "gym", "lunch", "perks", "perk",
        "competitive", "generous", "coverage", "matching", "allowance", "commuter", "childcare",
        "life", "disability", "retirement", "savings", "plan", "plans", "policy", "hours", "friendly",
        "fun", "exciting", "passionate", "passion", "curious", "curiosity", "humble", "kind",
        "agents", "agent", "agentic", "developers", "ecosystem", "primitives", "roadmap", "feedback",
        "demos", "demo", "templates", "template", "talks", "talk", "posts", "post", "videos", "video",
        "writing", "launch", "launches", "examples", "example", "repos", "repo",
        // What a bullet opens with when it is a sentence
        "collaborate", "partner", "participate", "contribute", "mentor", "write", "implement",
        "debug", "ship", "communicate", "define", "champion", "advocate", "identify", "investigate",
        "translate", "coordinate", "evaluate", "research", "create", "provide", "assist", "perform",
        "conduct", "analyze", "analyse", "report", "present", "prepare", "handle", "operate", "run",
        "optimize", "optimise", "automate", "migrate", "integrate", "deploy", "configure",
        "troubleshoot", "resolve", "respond", "document", "establish", "engage", "represent",
        "recruit", "hire", "onboard", "coach", "guide", "set", "shape", "track", "turn", "hit",
        "sit", "teach", "act", "serve", "take", "make", "keep", "bring", "show", "share", "learn",
        "stay", "get", "give", "put", "see", "know", "think", "want", "need", "like", "love",
        "you've", "you're", "we're", "they're", "it's", "that's", "here's", "what's", "don't",
        "can't", "won't", "let's", "we've", "i'm", "you'll", "we'll",
    ]
}

// MARK: - Coverage

/// Which of a posting's terms a résumé carries.
public struct Coverage: Sendable, Equatable, Codable {

    /// Terms from the posting that appear on the page.
    public let found: [String]

    /// Terms from the posting that do not.
    public let missing: [String]

    public init(found: [String], missing: [String]) {
        self.found = found
        self.missing = missing
    }

    public var total: Int { found.count + missing.count }

    /// Found over total, and 1 when the posting named nothing.
    public var ratio: Double { total == 0 ? 1 : Double(found.count) / Double(total) }
}

extension Resume {

    /// Which of the posting's terms this résumé carries, matched the way a
    /// scorer would: case-insensitively, forgiving a plural, and treating
    /// `Node.js`, `NodeJS` and `node js` as one word.
    public func coverage(of posting: Posting) -> Coverage {
        let index = Posting.Index(searchableText)
        var found: [String] = []
        var missing: [String] = []
        for term in posting.terms {
            if index.contains(term) { found.append(term) } else { missing.append(term) }
        }
        return Coverage(found: found, missing: missing)
    }

    /// Every word on the page, in no particular order. What a parser has to
    /// score against once it has extracted the text.
    public var searchableText: String {
        var parts: [String] = [
            profile.name, profile.headline, profile.location, summary, interests, references,
        ]
        parts += profile.links.map(\.label)

        func positions(_ items: [Position]) {
            for item in items {
                parts += [item.role, item.organisation, item.location, item.summary]
                parts += item.highlights + item.skills
            }
        }
        func education(_ items: [Education]) {
            for item in items {
                parts += [item.qualification, item.institution, item.location, item.grade]
                parts += item.highlights
            }
        }
        func projects(_ items: [Project]) {
            for item in items {
                parts += [item.name, item.role, item.summary, item.link?.label ?? ""]
                parts += item.highlights + item.skills
            }
        }
        func publications(_ items: [Publication]) {
            for item in items { parts += [item.title, item.venue, item.authors] }
        }
        func credentials(_ items: [Credential]) {
            for item in items { parts += [item.name, item.issuer, item.identifier] }
        }
        func awards(_ items: [Award]) {
            for item in items { parts += [item.name, item.issuer, item.summary] }
        }
        func grants(_ items: [Grant]) {
            for item in items { parts += [item.title, item.funder, item.role] }
        }
        func skills(_ items: [SkillGroup]) {
            for group in items { parts.append(group.name); parts += group.names }
        }
        func languages(_ items: [Language]) {
            for item in items { parts += [item.name, item.level] }
        }

        positions(experience); positions(volunteering); positions(teaching); positions(service)
        education(self.education)
        skills(self.skills)
        projects(self.projects)
        publications(self.publications); publications(talks)
        credentials(certifications); credentials(memberships)
        awards(self.awards)
        grants(self.grants)
        languages(self.languages)

        for section in custom {
            parts.append(section.title)
            for content in section.content {
                switch content {
                case .prose(let text): parts.append(text)
                case .list(let items): parts += items
                case .positions(let items): positions(items)
                case .education(let items): education(items)
                case .projects(let items): projects(items)
                case .publications(let items): publications(items)
                case .credentials(let items): credentials(items)
                case .awards(let items): awards(items)
                case .grants(let items): grants(items)
                case .skills(let items): skills(items)
                case .languages(let items): languages(items)
                }
            }
        }

        return parts.filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

extension Posting {

    /// A résumé's words, prepared for matching.
    struct Index {

        private let words: Set<String>
        private let joined: String

        init(_ text: String) {
            var set: Set<String> = []
            var sequence: [String] = []
            let separators: Set<Character> = [",", ";", "(", ")"]

            for piece in text.split(whereSeparator: { $0.isWhitespace || separators.contains($0) }) {
                var token = Substring(piece)
                while let last = token.last, Posting.trailing.contains(last) { token.removeLast() }
                while let first = token.first, Posting.leading.contains(first) { token.removeFirst() }
                guard !token.isEmpty else { continue }

                // "Node.js" as "nodejs"; "CI/CD" as "cicd"; "on-call" as
                // "oncall". Each side of a slash as well, so "TCP/IP"
                // answers to "IP".
                let normalised = Posting.normalise(String(token))
                set.insert(normalised)
                sequence.append(normalised)
                for side in token.split(separator: "/") where side.count > 1 {
                    set.insert(Posting.normalise(String(side)))
                }
            }
            words = set
            joined = " " + sequence.joined(separator: " ") + " "
        }

        func contains(_ term: String) -> Bool {
            let parts = term.split(whereSeparator: { $0.isWhitespace }).map { Posting.normalise(String($0)) }
            guard let last = parts.last, !last.isEmpty else { return false }

            if parts.count == 1 {
                if Posting.forms(of: last).contains(where: { words.contains($0) }) { return true }
                // "CI/CD" on the page as "CI CD"; "Node.js" as "Node JS".
                let spaced = term.lowercased().map { ".-/".contains($0) ? " " : $0 }
                let phrase = String(spaced).split(separator: " ").joined(separator: " ")
                return phrase.contains(" ") && joined.contains(" \(phrase) ")
            }
            let head = parts.dropLast().joined(separator: " ")
            return Posting.forms(of: last).contains { joined.contains(" \(head) \($0) ") }
        }
    }

    /// Lowercased, with the punctuation that spelling varies on removed.
    static func normalise(_ word: String) -> String {
        word.lowercased().filter { $0 != "." && $0 != "-" && $0 != "/" && $0 != "_" }
    }

    /// The word, its plural, and its singular.
    static func forms(of word: String) -> [String] {
        var forms = [word, word + "s", word + "es"]
        if word.hasSuffix("es"), word.count > 3 { forms.append(String(word.dropLast(2))) }
        if word.hasSuffix("s"), word.count > 2 { forms.append(String(word.dropLast())) }
        return forms
    }
}
