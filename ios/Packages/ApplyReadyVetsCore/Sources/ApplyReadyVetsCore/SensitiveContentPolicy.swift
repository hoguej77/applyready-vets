import Foundation

/// Conservative, local pattern checks used before AI, export, handoff, or
/// professional-profile drafting. This is a warning layer, not a complete DLP
/// system, so the UI still tells the candidate to review every output.
public enum SensitiveContentPolicy {
    private struct Pattern {
        let code: String
        let title: String
        let severity: Severity
        let expression: String
    }

    private static let patterns: [Pattern] = [
        Pattern(
            code: "ssn",
            title: "Possible Social Security number",
            severity: .critical,
            expression: #"(?<!\d)\d{3}[\s-]\d{2}[\s-]\d{4}(?!\d)|\b(?:SSN|Social\s+Security(?:\s+number)?)\s*[:#-]?\s*\d{9}\b"#
        ),
        Pattern(
            code: "dob",
            title: "Possible date of birth",
            severity: .critical,
            expression: #"\b(?:DOB|Date\s+of\s+Birth|Birth\s+Date)\b\s*[:#-]?\s*(?:\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|[A-Za-z]+\s+\d{1,2},?\s+\d{4})"#
        ),
        Pattern(
            code: "banking",
            title: "Possible banking information",
            severity: .critical,
            expression: #"\b(?:routing|bank\s+account|account)\s+(?:number|no\.?)\s*[:#-]?\s*\d{6,17}\b"#
        ),
        Pattern(
            code: "clearance_detail",
            title: "Potentially sensitive clearance or operational detail",
            severity: .critical,
            expression: #"\b(?:special access program|classified (?:mission|operation|material|details?)|secret mission|code[- ]word|compartmented (?:mission|operation|details?))\b"#
        ),
        Pattern(
            code: "medical",
            title: "Personal medical or disability detail",
            severity: .warning,
            expression: #"\b(?:disability rating|service-connected disability|diagnosis|medical condition)\b"#
        ),
    ]

    public static func containsSensitiveContent(_ text: String) -> Bool {
        patterns.contains { matches(text, expression: $0.expression) }
    }

    public static func hasCriticalFinding(in text: String) -> Bool {
        patterns.contains {
            $0.severity == .critical && matches(text, expression: $0.expression)
        }
    }

    /// AI assistance pauses for every configured sensitive pattern, including
    /// medical or disability details that remain warnings rather than hard
    /// export blockers.
    public static func shouldPauseAI(in text: String) -> Bool {
        containsSensitiveContent(text)
    }

    /// Contact details can be appropriate in a resume but should not be lifted
    /// into LinkedIn About text or experience highlights automatically.
    public static func shouldExcludeFromProfileDraft(_ text: String) -> Bool {
        if containsSensitiveContent(text) { return true }
        let profileExclusions = [
            #"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#,
            #"(?<!\d)(?:\+?1[\s.-]?)?(?:\(\d{3}\)|\d{3})[\s.-]\d{3}[\s.-]\d{4}(?!\d)"#,
            #"\b(?:https?://|www\.|linkedin\.com/)\S+"#,
        ]
        return profileExclusions.contains { matches(text, expression: $0) }
    }

    public static func findings(in text: String) -> [SafetyFinding] {
        var findings: [SafetyFinding] = []
        let lines = text.components(separatedBy: .newlines)
        for (lineIndex, line) in lines.enumerated() where !line.isEmpty {
            for pattern in patterns where matches(line, expression: pattern.expression) {
                findings.append(SafetyFinding(
                    code: pattern.code,
                    severity: pattern.severity,
                    title: pattern.title,
                    detail: "Review and remove this information before sharing the resume or sending it to AI.",
                    evidenceID: String(format: "safety:%05d", lineIndex + 1)
                ))
            }
        }
        return unique(findings)
    }

    private static func matches(_ text: String, expression: String) -> Bool {
        guard let regex = try? NSRegularExpression(
            pattern: expression,
            options: [.caseInsensitive]
        ) else { return false }
        return regex.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        ) != nil
    }

    private static func unique(_ findings: [SafetyFinding]) -> [SafetyFinding] {
        var seen = Set<String>()
        return findings.filter { seen.insert($0.id).inserted }
    }
}
