import Foundation

/// A private, deterministic baseline that keeps the core application useful
/// without a network connection or generative model.
public enum LocalCareerEngine {
    private static let headings: Set<String> = [
        "summary", "professional summary", "experience", "professional experience",
        "military experience", "education", "skills", "core competencies",
        "certifications", "licenses", "awards", "volunteer",
    ]

    private static let stopwords: Set<String> = [
        "a", "an", "and", "or", "the", "but", "with", "for", "to", "from", "on", "in",
        "at", "as", "by", "of", "be", "is", "are", "was", "were", "will", "would",
        "can", "could", "that", "this", "your", "you", "we", "our", "they", "their",
        "role", "job", "position", "work", "team", "years", "experience", "required",
        "requirements", "preferred", "must", "have", "including", "responsible",
        "company", "title",
    ]

    private static let actionVerbs: Set<String> = [
        "led", "managed", "trained", "planned", "delivered", "improved", "reduced",
        "increased", "built", "maintained", "coordinated", "supervised", "analyzed",
        "implemented", "operated", "developed",
    ]

    private static let militaryTranslations: [(String, String)] = [
        ("11B", "Infantryman (11B) — military operations and security experience"),
        ("88M", "Motor Transport Operator (88M) — transportation and logistics operations"),
        ("68W", "Combat Medic Specialist (68W) — emergency care and field medical support"),
        ("35F", "Intelligence Analyst (35F) — intelligence research and analytical support"),
        ("25B", "Information Technology Specialist (25B) — information systems support"),
        ("42A", "Human Resources Specialist (42A) — personnel and administrative support"),
        ("92Y", "Unit Supply Specialist (92Y) — inventory and supply operations"),
        ("0311", "Rifleman (0311) — military operations and security experience"),
        ("3531", "Motor Vehicle Operator (3531) — fleet and transportation operations"),
        ("3D1", "Client Systems specialty — information technology support"),
        ("3D2", "Cyber Systems specialty — systems and infrastructure operations"),
    ]

    private static let acronyms: [(String, String)] = [
        ("NCOIC", "Noncommissioned Officer in Charge (NCOIC)"),
        ("OIC", "Officer in Charge (OIC)"),
        ("MOS", "Military Occupational Specialty (MOS)"),
        ("AFSC", "Air Force Specialty Code (AFSC)"),
        ("OPSEC", "Operations Security (OPSEC)"),
        ("KSA", "Knowledge, Skills, and Abilities (KSA)"),
    ]

    public static func analyze(_ request: TailorRequest) -> TailorResponse {
        let evidence = canonicalEvidence(
            resumeText: request.resumeText,
            profile: request.profile
        )
        let resumeEvidence = evidence.filter { $0.source == "resume" }
        let profileEvidence = evidence.filter { $0.source == "veteran_input" }
        // Scan the complete resume, not the bounded evidence ledger. This keeps
        // a sensitive value near the end of a large but valid resume visible.
        let safetyFindings = SensitiveContentPolicy.findings(in: request.resumeText)
        let job = analyzeJob(jobText: request.jobText, resumeText: request.resumeText)
        var warnings: [String] = []

        var candidates = veteranProposals(from: resumeEvidence)
        candidates.append(contentsOf: profileProposals(
            resumeText: request.resumeText,
            profileEvidence: profileEvidence
        ))

        var proposals: [ProposedEdit] = []
        var seen = Set<String>()
        for proposal in candidates {
            let result = TruthLock.validate(proposal, evidence: evidence, targetTitle: job.title)
            guard result.accepted else {
                warnings.append("Truth Lock rejected one proposal: \(result.reason)")
                continue
            }
            guard request.resumeText.contains(proposal.originalText) else {
                warnings.append("Truth Lock rejected one proposal because its source text was not found.")
                continue
            }
            let key = proposal.originalText.trimmingCharacters(in: .whitespacesAndNewlines)
                + "\u{001F}"
                + proposal.proposedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard seen.insert(key).inserted else { continue }
            proposals.append(proposal)
        }

        if resumeEvidence.isEmpty {
            warnings.append("No usable evidence lines were found in the resume.")
        }
        if job.federal {
            warnings.append(
                "Federal applications require announcement-specific review, dates, hours per week, and current page-limit validation."
            )
        }
        if !job.riskFlags.isEmpty {
            warnings.append(
                "The job posting triggered safety warnings. Verify the employer before sharing personal documents."
            )
        }
        if request.useAI && !request.aiConsent {
            warnings.append(
                "AI was not used because consent was not granted. Private rules and Truth Lock completed the analysis."
            )
        }

        return TailorResponse(
            analysisID: UUID().uuidString,
            engine: "private-local-rules+truth-lock",
            evidence: evidence,
            job: job,
            proposals: proposals,
            gapQuestions: gapQuestions(for: job),
            safetyFindings: safetyFindings,
            integrityWarnings: unique(warnings),
            scores: readinessScores(
                resumeText: request.resumeText,
                job: job,
                evidence: resumeEvidence,
                safetyFindings: safetyFindings
            )
        )
    }

    /// Rebuilds the evidence ledger from the supplied inputs. Export uses this
    /// instead of trusting a persisted or service-supplied response ledger.
    public static func canonicalEvidence(
        resumeText: String,
        profile: CandidateProfile
    ) -> [EvidenceItem] {
        buildResumeEvidence(resumeText) + buildProfileEvidence(profile)
    }

    /// A local-rule provenance label is not enough to bypass Truth Lock. Only
    /// the exact, allowlisted military-code or acronym transforms emitted by
    /// this engine are treated as supported terminology expansions.
    static func isExactLocalRuleProposal(
        _ proposal: ProposedEdit,
        citedEvidence: [EvidenceItem],
        allEvidence: [EvidenceItem]
    ) -> Bool {
        guard proposal.source == "private-local-rules",
              proposal.evidenceIDs.count == 1,
              citedEvidence.count == 1,
              let cited = citedEvidence.first else {
            return false
        }

        switch cited.source {
        case "resume":
            guard normalizedEvidenceText(proposal.originalText) == normalizedEvidenceText(cited.text),
                  let expected = localRuleReplacement(for: cited.text) else {
                return false
            }
            return normalizedEvidenceText(proposal.effectiveText) == normalizedEvidenceText(expected)
        case "veteran_input":
            guard isProfileInsertionAnchor(proposal.originalText),
                  allEvidence.contains(where: {
                      guard $0.source == "resume" else { return false }
                      let anchor = normalizedEvidenceText(proposal.originalText)
                      return normalizedEvidenceText($0.text) == anchor ||
                          normalizedEvidenceText($0.section) == anchor
                  }),
                  let translation = militaryTranslation(in: cited.text) else {
                return false
            }
            let expected = "\(proposal.originalText)\n\(translation)"
            return normalizedEvidenceText(proposal.effectiveText) == normalizedEvidenceText(expected)
        default:
            return false
        }
    }

    /// Returns the same conservative federal-posting classification used by
    /// the deterministic analyzer. The app uses this before analysis so an
    /// Auto workspace cannot skip federal review and export safeguards.
    public static func postingAppearsFederal(_ jobText: String) -> Bool {
        let lower = jobText.lowercased()
        return ["usajobs", "specialized experience", "gs-", "federal service"]
            .contains { lower.contains($0) }
    }

    public static func linkedInKit(
        for request: ExportRequest,
        reviewedResumeText finalResume: String
    ) -> LinkedInProfileKit {
        let finalLines = normalizedLines(finalResume)
        let targetRole = request.profile.targetRole.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackRole = request.response.job.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let role = targetRole.isEmpty ? fallbackRole : targetRole
        let skillEvidenceLines = linesEligibleForSkillSuggestions(finalLines)
        let resumeTokens = Set(cleanTokens(skillEvidenceLines.joined(separator: "\n")))
        let skills = request.response.job.keywords
            .filter { resumeTokens.contains($0.lowercased()) }
            .prefix(12)
            .map(displaySkill)

        let safeLines = finalLines.filter {
            !SensitiveContentPolicy.shouldExcludeFromProfileDraft($0) &&
                !isResumeHeading($0)
        }
        let highlights = safeLines.filter { line in
            let tokens = Set(cleanTokens(line))
            return !tokens.isDisjoint(with: actionVerbs) || containsNumber(line)
        }
        let groundedHighlights = Array(highlights.prefix(5))
        let topSkill = skills.first
        var headlines: [String] = []
        if !role.isEmpty {
            headlines.append(role)
            if let topSkill {
                headlines.append("\(role) | \(topSkill)")
            }
            if !request.profile.militaryService.isEmpty {
                headlines.append("Veteran | \(role)")
            }
        } else if let topSkill {
            headlines.append("\(topSkill) Professional")
        }
        if headlines.isEmpty {
            headlines.append("Career Professional")
        }

        let aboutText: String
        if groundedHighlights.isEmpty {
            aboutText = role.isEmpty
                ? "Use verified resume evidence to complete this About section."
                : "I am pursuing \(role) opportunities. Add only achievements you can support with your records."
        } else {
            let focus = role.isEmpty ? "my next opportunity" : role + " opportunities"
            aboutText = """
            I am pursuing \(focus). My background includes:

            \(groundedHighlights.map { "• \($0)" }.joined(separator: "\n"))

            I welcome conversations about roles where this experience can contribute.
            """
        }

        let company = request.response.job.company.trimmingCharacters(in: .whitespacesAndNewlines)
        let companyPhrase = company.isEmpty ? "your organization" : company
        let rolePhrase = role.isEmpty ? "relevant opportunities" : role + " opportunities"

        return LinkedInProfileKit(
            headlineOptions: unique(headlines),
            aboutText: aboutText,
            skills: skills,
            experienceHighlights: groundedHighlights,
            featuredIdeas: [
                "Add a sanitized work sample that contains no controlled, personal, or employer-confidential information.",
                "Feature a verified credential, portfolio item, or public project relevant to the target role.",
            ],
            connectionMessage: "Hello — I am exploring \(rolePhrase) and would value connecting with professionals at \(companyPhrase).",
            recruiterMessage: "Hello — I am interested in \(rolePhrase) at \(companyPhrase). I can share a tailored resume built from verified experience if the role may be a fit.",
            checklist: [
                "Use a clear, current photo and a simple background image.",
                "Match the headline and About section to the roles you are actually pursuing.",
                "Confirm every date, title, credential, number, and clearance statement before publishing.",
                "Remove unit-sensitive, medical, disability, and controlled operational details.",
                "Turn off profile-update broadcasts while making large edits if you prefer privacy.",
            ],
            disclaimer: "Candidate-reviewed draft based on the resume and profile you supplied. Pattern checks cannot prove every qualitative statement; verify every line before publishing. ApplyReady Vets does not post to LinkedIn."
        )
    }

    private static func buildResumeEvidence(_ text: String, maxItems: Int = 300) -> [EvidenceItem] {
        var result: [EvidenceItem] = []
        var section = "resume"
        for line in normalizedLines(text) {
            let heading = line.lowercased()
                .replacingOccurrences(of: #"[^a-z ]"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if headings.contains(heading) {
                section = heading
                continue
            }
            result.append(EvidenceItem(
                id: String(format: "resume:%03d", result.count + 1),
                source: "resume",
                section: section,
                text: String(line.prefix(800))
            ))
            if result.count >= maxItems { break }
        }
        return result
    }

    private static func buildProfileEvidence(_ profile: CandidateProfile) -> [EvidenceItem] {
        profile.militaryService.enumerated().compactMap { index, service in
            let values: [(String, String)] = [
                ("Branch", service.branch),
                ("Component", service.component),
                ("Rank", service.rank),
                ("Pay grade", service.payGrade),
                ("Occupation code", service.occupationCode),
                ("Occupation title", service.occupationTitle),
                ("Service start", service.serviceStart),
                ("Service end", service.serviceEnd),
            ]
            let text = values.compactMap { label, value -> String? in
                let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return cleaned.isEmpty ? nil : "\(label): \(cleaned)"
            }.joined(separator: "; ")
            guard !text.isEmpty else { return nil }
            return EvidenceItem(
                id: String(format: "veteran:%03d", index + 1),
                source: "veteran_input",
                section: "service profile",
                text: String(text.prefix(800))
            )
        }
    }

    private static func analyzeJob(jobText: String, resumeText: String) -> JobAnalysis {
        let lines = normalizedLines(jobText)
        let company = capturedField(
            in: jobText,
            pattern: #"Company\s*[:\-]\s*([^\n]+)"#
        )
        var title = capturedField(
            in: jobText,
            pattern: #"(?:Job\s*Title|Title)\s*[:\-]\s*([^\n]+)"#
        )
        if title.isEmpty {
            title = String((lines.first ?? "").prefix(100))
        }
        let requirements = lines.filter {
            containsRegex(
                $0,
                pattern: #"\b(?:required|requirements|must have|minimum qualification|specialized experience)\b"#,
                caseInsensitive: true
            )
        }.prefix(12).map { String($0.prefix(500)) }

        let keywordLines = lines.filter { line in
            !containsRegex(
                line,
                pattern: #"^(?:company|job\s*title|title)\s*[:\-]"#,
                caseInsensitive: true
            ) &&
            !containsRegex(
                line,
                pattern: #"\b(?:open to veterans|veterans recruitment appointment|vra|veoa|veterans'? preference)\b"#,
                caseInsensitive: true
            )
        }
        let keywords = rankedKeywords(keywordLines.joined(separator: "\n"), limit: 30)
        let resumeTokens = Set(affirmedTokens(resumeText))
        let missing = Array(keywords.filter { !resumeTokens.contains($0) }.prefix(12))
        let lower = jobText.lowercased()

        let scamPatterns: [(String, String)] = [
            ("upfront_fee", #"(?:pay|payment).*(?:application|training|setup|before.*start)"#),
            ("messaging_interview", #"(?:(?:telegram|whatsapp).{0,30}(?:interview|chat|hr)|(?:interview|chat|hr).{0,30}(?:telegram|whatsapp))"#),
            ("remote_access", #"(?:install|download).*(?:anydesk|teamviewer|remote access)"#),
            ("bank_or_ssn", #"(?:ssn|social security|bank info|routing number|account number)"#),
            ("gift_crypto_wire", #"(?:gift card|bitcoin|crypto|wire transfer)"#),
        ]
        let risks = scamPatterns.compactMap { name, pattern in
            containsRegex(jobText, pattern: pattern, caseInsensitive: true) ? name : nil
        }

        return JobAnalysis(
            company: company,
            title: title,
            keywords: keywords,
            requiredQualifications: requirements,
            missingKeywords: missing,
            federal: postingAppearsFederal(lower),
            openToVeterans: [
                "open to veterans", "veterans recruitment appointment", "vra", "veoa",
                "veterans' preference", "veterans preference", "30% or more disabled veteran",
            ].contains { lower.contains($0) },
            riskFlags: risks
        )
    }

    private static func gapQuestions(for job: JobAnalysis) -> [GapQuestion] {
        job.missingKeywords.prefix(6).enumerated().map { index, term in
            GapQuestion(
                requirement: term,
                question: "Do you have documented military, civilian, volunteer, or training experience with \(term)?",
                priority: index < 2 ? "high" : "medium"
            )
        }
    }

    private static func veteranProposals(from evidence: [EvidenceItem], limit: Int = 8) -> [ProposedEdit] {
        var proposals: [ProposedEdit] = []
        for item in evidence {
            var replacement = item.text
            var rationale = ""
            for (code, translation) in militaryTranslations {
                let pattern = #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: code))(?!\w)"#
                if containsRegex(replacement, pattern: pattern, caseInsensitive: true) {
                    replacement = replaceFirst(
                        in: replacement,
                        pattern: pattern,
                        with: translation,
                        caseInsensitive: true
                    )
                    rationale = "Translate the military occupation into plain civilian language while preserving the code."
                    break
                }
            }
            if replacement == item.text {
                for (acronym, expansion) in acronyms where !replacement.contains(expansion) {
                    let pattern = #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: acronym))(?!\w)"#
                    if containsRegex(replacement, pattern: pattern) {
                        replacement = replaceFirst(in: replacement, pattern: pattern, with: expansion)
                        rationale = "Expand a military acronym once so a civilian recruiter does not have to interpret it."
                        break
                    }
                }
            }
            guard replacement != item.text else { continue }
            proposals.append(ProposedEdit(
                id: "local:\(item.id)",
                section: item.section,
                originalText: item.text,
                proposedText: replacement,
                rationale: rationale,
                evidenceIDs: [item.id],
                confidence: 0.82,
                source: "private-local-rules"
            ))
            if proposals.count >= limit { break }
        }
        return proposals
    }

    private static func profileProposals(
        resumeText: String,
        profileEvidence: [EvidenceItem],
        limit: Int = 3
    ) -> [ProposedEdit] {
        guard let headingMatch = firstMatch(
            in: resumeText,
            pattern: #"(?m)^[ \t]*(MILITARY EXPERIENCE|EXPERIENCE)[ \t]*$"#,
            caseInsensitive: true
        ), let range = Range(headingMatch.range, in: resumeText) else {
            return []
        }
        let anchor = String(resumeText[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        var proposals: [ProposedEdit] = []
        for item in profileEvidence {
            for (code, translation) in militaryTranslations {
                let pattern = #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: code))(?!\w)"#
                guard containsRegex(item.text, pattern: pattern, caseInsensitive: true) else { continue }
                guard !containsRegex(resumeText, pattern: pattern, caseInsensitive: true) else { break }
                proposals.append(ProposedEdit(
                    id: "local:profile:\(item.id):\(code)",
                    section: "military experience",
                    originalText: anchor,
                    proposedText: "\(anchor)\n\(translation)",
                    rationale: "Offer a conservative civilian translation for the occupation code the user entered. Verify it before approval.",
                    evidenceIDs: [item.id],
                    confidence: 0.72,
                    source: "private-local-rules"
                ))
                break
            }
            if proposals.count >= limit { break }
        }
        return proposals
    }

    private static func readinessScores(
        resumeText: String,
        job: JobAnalysis,
        evidence: [EvidenceItem],
        safetyFindings: [SafetyFinding]
    ) -> ReadinessScores {
        let resumeTokens = Set(affirmedTokens(resumeText))
        let jobTokens = Set(job.keywords)
        let coverage = Int((100.0 * Double(resumeTokens.intersection(jobTokens).count)
            / Double(max(1, jobTokens.count))).rounded())

        let strongLines = evidence.filter { item in
            let tokens = Set(cleanTokens(item.text))
            return !tokens.isDisjoint(with: actionVerbs) && containsNumber(item.text)
        }.count
        let evidenceStrength = min(
            100,
            Int((100.0 * Double(strongLines) / Double(max(1, min(8, evidence.count)))).rounded())
        )

        let capitals = regexMatches(in: resumeText, pattern: #"\b[A-Z][A-Z0-9/+-]{2,}\b"#)
        let explained = capitals.filter { acronym in
            containsRegex(
                resumeText,
                pattern: #"[A-Za-z ]+\(\#(NSRegularExpression.escapedPattern(for: acronym))\)"#
            )
        }.count
        let acronymClarity = capitals.isEmpty
            ? 100
            : Int((100.0 * Double(explained) / Double(capitals.count)).rounded())

        return ReadinessScores(
            qualificationCoverage: coverage,
            evidenceStrength: evidenceStrength,
            acronymClarity: acronymClarity,
            applicationReadiness: 0,
            disclaimer: "These document checks show job-keyword overlap, evidence strength, and acronym clarity. They cannot verify qualifications, simulate an ATS, or predict hiring; no overall readiness score is calculated."
        )
    }

    private static func normalizedLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines).compactMap { raw in
            let collapsed = raw
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: " \t•-|"))
            return collapsed.isEmpty ? nil : collapsed
        }
    }

    private static func cleanTokens(_ text: String) -> [String] {
        regexMatches(in: text, pattern: #"[A-Za-z][A-Za-z0-9+#./-]{1,}"#).compactMap { raw in
            let token = raw.trimmingCharacters(in: CharacterSet(charactersIn: "./-")).lowercased()
            return token.count > 1 && !stopwords.contains(token) ? token : nil
        }
    }

    private static func affirmedTokens(_ text: String) -> [String] {
        normalizedLines(text)
            .filter { !isUnassertedSkillLine($0) }
            .flatMap(cleanTokens)
    }

    private static func linesEligibleForSkillSuggestions(_ lines: [String]) -> [String] {
        var inSkillsSection = false
        return lines.compactMap { line in
            let normalized = line.lowercased()
                .replacingOccurrences(of: #"[^a-z ]"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if headings.contains(normalized) {
                inSkillsSection = ["skills", "core competencies", "certifications", "licenses"]
                    .contains(normalized)
                return nil
            }
            if isUnassertedSkillLine(line) {
                return nil
            }
            let tokens = Set(cleanTokens(line))
            return inSkillsSection || !tokens.isDisjoint(with: actionVerbs) ? line : nil
        }
    }

    private static func isResumeHeading(_ line: String) -> Bool {
        let normalized = line.lowercased()
            .replacingOccurrences(of: #"[^a-z ]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return headings.contains(normalized)
    }

    private static func isUnassertedSkillLine(_ line: String) -> Bool {
        let patterns = [
            #"\b(?:no|not|never|without|lack(?:ed|ing|s)?|cannot|can't|couldn't|didn't|doesn't|don't|wasn't|weren't|unfamiliar)\b"#,
            #"\b(?:basic|beginner|elementary|foundational|fundamentals|introductory|limited|familiarity|exposure)\b"#,
            #"\b(?:training|coursework|course|studied|learning)\b"#,
        ]
        return patterns.contains {
            containsRegex(line, pattern: $0, caseInsensitive: true)
        }
    }

    private static func localRuleReplacement(for text: String) -> String? {
        if let (code, translation) = militaryTranslations.first(where: { code, _ in
            containsRegex(
                text,
                pattern: #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: code))(?!\w)"#,
                caseInsensitive: true
            )
        }) {
            return replaceFirst(
                in: text,
                pattern: #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: code))(?!\w)"#,
                with: translation,
                caseInsensitive: true
            )
        }
        if let (acronym, expansion) = acronyms.first(where: { acronym, expansion in
            !text.contains(expansion) && containsRegex(
                text,
                pattern: #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: acronym))(?!\w)"#
            )
        }) {
            return replaceFirst(
                in: text,
                pattern: #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: acronym))(?!\w)"#,
                with: expansion
            )
        }
        return nil
    }

    private static func militaryTranslation(in text: String) -> String? {
        militaryTranslations.first { code, _ in
            containsRegex(
                text,
                pattern: #"(?<!\w)\#(NSRegularExpression.escapedPattern(for: code))(?!\w)"#,
                caseInsensitive: true
            )
        }?.1
    }

    private static func normalizedEvidenceText(_ text: String) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    private static func isProfileInsertionAnchor(_ text: String) -> Bool {
        ["experience", "military experience"].contains(normalizedEvidenceText(text))
    }

    private static func rankedKeywords(_ text: String, limit: Int) -> [String] {
        let tokens = cleanTokens(text)
        var count: [String: Int] = [:]
        var firstSeen: [String: Int] = [:]
        for (index, token) in tokens.enumerated() {
            count[token, default: 0] += 1
            firstSeen[token, default: index] = min(firstSeen[token, default: index], index)
        }
        return count.keys.sorted { lhs, rhs in
            let leftCount = count[lhs, default: 0]
            let rightCount = count[rhs, default: 0]
            if leftCount != rightCount { return leftCount > rightCount }
            let leftIndex = firstSeen[lhs, default: .max]
            let rightIndex = firstSeen[rhs, default: .max]
            if leftIndex != rightIndex { return leftIndex < rightIndex }
            return lhs < rhs
        }.prefix(limit).map(\.self)
    }

    private static func capturedField(in text: String, pattern: String) -> String {
        guard let match = firstMatch(in: text, pattern: pattern, caseInsensitive: true),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return ""
        }
        return String(text[range])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(120)
            .description
    }

    private static func containsNumber(_ text: String) -> Bool {
        containsRegex(text, pattern: #"(?<!\w)(?:\$)?\d+(?:[.,]\d+)*(?:%|[KkMm])?(?!\w)"#)
    }

    private static func displaySkill(_ skill: String) -> String {
        let special: [String: String] = [
            "ai": "AI", "aws": "AWS", "crm": "CRM", "hr": "HR", "it": "IT",
            "sql": "SQL", "ui": "UI", "ux": "UX",
        ]
        return special[skill.lowercased()] ?? skill.capitalized
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func containsRegex(
        _ text: String,
        pattern: String,
        caseInsensitive: Bool = false
    ) -> Bool {
        firstMatch(in: text, pattern: pattern, caseInsensitive: caseInsensitive) != nil
    }

    private static func firstMatch(
        in text: String,
        pattern: String,
        caseInsensitive: Bool = false
    ) -> NSTextCheckingResult? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        return expression.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        )
    }

    private static func regexMatches(in text: String, pattern: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return expression.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    private static func replaceFirst(
        in text: String,
        pattern: String,
        with replacement: String,
        caseInsensitive: Bool = false
    ) -> String {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options),
              let match = expression.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ),
              let range = Range(match.range, in: text) else {
            return text
        }
        return text.replacingCharacters(in: range, with: replacement)
    }
}
