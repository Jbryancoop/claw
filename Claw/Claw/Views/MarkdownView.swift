import SwiftUI

/// Renders markdown text as properly formatted SwiftUI views.
/// Handles headings, bold, italic, lists, horizontal rules, and code blocks.
struct MarkdownView: View {
    let text: String
    let baseFont: Font

    init(_ text: String, font: Font = .body) {
        self.text = text
        self.baseFont = font
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MDBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .paragraph(let text):
            inlineText(text)
                .font(baseFont)
        case .listItem(let text):
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .font(baseFont)
                inlineText(text)
                    .font(baseFont)
            }
        case .horizontalRule:
            Divider()
                .padding(.vertical, 4)
        case .codeBlock(let code):
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .blank:
            Spacer().frame(height: 4)
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        inlineText(text)
            .font(level == 1 ? .title2.bold() : level == 2 ? .title3.bold() : .headline)
            .padding(.top, level == 1 ? 4 : 2)
    }

    private func inlineText(_ text: String) -> Text {
        // Parse inline markdown: **bold**, *italic*, `code`
        var result = Text("")
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            if remaining.hasPrefix("**"), let endIdx = remaining.dropFirst(2).range(of: "**")?.lowerBound {
                let content = remaining[remaining.index(remaining.startIndex, offsetBy: 2)..<endIdx]
                result = result + Text(String(content)).bold()
                remaining = remaining[remaining.index(endIdx, offsetBy: 2)...]
            } else if remaining.hasPrefix("*"), let endIdx = remaining.dropFirst(1).range(of: "*")?.lowerBound {
                let content = remaining[remaining.index(remaining.startIndex, offsetBy: 1)..<endIdx]
                result = result + Text(String(content)).italic()
                remaining = remaining[remaining.index(endIdx, offsetBy: 1)...]
            } else if remaining.hasPrefix("`"), let endIdx = remaining.dropFirst(1).range(of: "`")?.lowerBound {
                let content = remaining[remaining.index(remaining.startIndex, offsetBy: 1)..<endIdx]
                result = result + Text(String(content)).font(.system(.body, design: .monospaced)).foregroundColor(.secondary)
                remaining = remaining[remaining.index(endIdx, offsetBy: 1)...]
            } else {
                // Consume up to next special character
                var nextSpecial = remaining.endIndex
                for marker in ["**", "*", "`"] {
                    if let r = remaining.dropFirst(1).range(of: marker) {
                        if r.lowerBound < nextSpecial {
                            nextSpecial = r.lowerBound
                        }
                    }
                }
                let plain = remaining[remaining.startIndex..<nextSpecial]
                result = result + Text(String(plain))
                remaining = remaining[nextSpecial...]
            }
        }
        return result
    }

    // MARK: - Block Parser

    private enum MDBlock {
        case heading(Int, String)
        case paragraph(String)
        case listItem(String)
        case horizontalRule
        case codeBlock(String)
        case blank
    }

    private func parseBlocks() -> [MDBlock] {
        let lines = text.components(separatedBy: "\n")
        var blocks: [MDBlock] = []
        var inCodeBlock = false
        var codeLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code blocks
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
                    codeLines = []
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                }
                continue
            }
            if inCodeBlock {
                codeLines.append(line)
                continue
            }

            // Blank line
            if trimmed.isEmpty {
                blocks.append(.blank)
                continue
            }

            // Horizontal rule
            if trimmed.allSatisfy({ $0 == "-" || $0 == " " }) && trimmed.filter({ $0 == "-" }).count >= 3 {
                blocks.append(.horizontalRule)
                continue
            }

            // Headings
            if trimmed.hasPrefix("### ") {
                blocks.append(.heading(3, String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(.heading(2, String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(.heading(1, String(trimmed.dropFirst(2))))
            }
            // List items
            else if trimmed.hasPrefix("- ") {
                blocks.append(.listItem(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("* ") {
                blocks.append(.listItem(String(trimmed.dropFirst(2))))
            } else if let r = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                blocks.append(.listItem(String(trimmed[r.upperBound...])))
            }
            // Paragraph
            else {
                blocks.append(.paragraph(trimmed))
            }
        }

        // Close unclosed code block
        if inCodeBlock && !codeLines.isEmpty {
            blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
        }

        return blocks
    }
}

/// Plain text summary for list previews (strips markdown syntax)
func markdownPlainText(_ text: String) -> String {
    var lines = text.components(separatedBy: "\n")
    lines = lines.map { line in
        var l = line
        // Strip heading markers on each line
        l = l.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        // Strip list markers
        l = l.replacingOccurrences(of: #"^[-*]\s+"#, with: "", options: .regularExpression)
        l = l.replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression)
        // Strip bold/italic
        l = l.replacingOccurrences(of: "**", with: "")
        l = l.replacingOccurrences(of: "*", with: "")
        // Strip code markers
        l = l.replacingOccurrences(of: "`", with: "")
        // Strip horizontal rules
        if l.trimmingCharacters(in: .whitespaces).allSatisfy({ $0 == "-" }) && l.filter({ $0 == "-" }).count >= 3 {
            return ""
        }
        return l
    }
    let result = lines.joined(separator: " ")
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}
