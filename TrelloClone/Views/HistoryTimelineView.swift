import SwiftUI

// MARK: - HistoryTimelineView
// Reusable Notion-style vertical timeline with color-coded action dots,
// connecting lines, and relative timestamps. Used in CardDetailView
// and potentially board-level history views.

struct HistoryTimelineView: View {
    let entries: [HistoryEntry]

    var body: some View {
        if entries.isEmpty {
            Text("No history yet")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.vertical, AppTheme.spacingSM)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    HStack(alignment: .top, spacing: AppTheme.spacingMD) {
                        // Timeline dot + connecting line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(dotColor(for: entry.action))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)

                            if index < entries.count - 1 {
                                Rectangle()
                                    .fill(AppTheme.cardBorder)
                                    .frame(width: 1)
                                    .frame(minHeight: 24)
                            }
                        }
                        .frame(width: 8)

                        // Entry content
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.description)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)

                            Text(entry.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.bottom, AppTheme.spacingSM)

                        Spacer()
                    }
                }
            }
        }
    }

    /// Color-codes timeline dots by action type
    private func dotColor(for action: HistoryEntry.Action) -> Color {
        switch action {
        case .created: return Color(hex: 0x34A853)   // Green
        case .updated: return Color(hex: 0x4285F4)   // Blue
        case .deleted: return Color(hex: 0xEA4335)   // Red
        case .moved:   return Color(hex: 0xFA7B17)   // Orange
        }
    }
}
