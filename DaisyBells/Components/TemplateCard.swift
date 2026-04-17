import SwiftUI

@MainActor
struct TemplateCard: View {
    let name: String
    let exercises: [ExerciseInfo]
    let isExpanded: Bool
    let startDisabled: Bool?
    let onToggleExpand: () -> Void
    let onStart: (() -> Void)?
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onViewDetail: (() -> Void)?

    let style: Style

    enum Style {
        case card
        case listRow
    }

    struct ExerciseInfo: Identifiable {
        let id: UUID
        let name: String
        let typeName: String?

        init(from te: SchemaV1.TemplateExercise) {
            self.id = te.id
            self.name = te.exercise?.name ?? "Unknown"
            self.typeName = te.exercise?.type.displayName
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerButton

            if isExpanded {
                expandedContent
            }
        }
        .modifier(CardStyleModifier(style: style))
    }

    // MARK: - Header

    private var headerButton: some View {
        Button {
            onToggleExpand()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    Text("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                if let startDisabled, let onStart {
                    Button {
                        onStart()
                    } label: {
                        Text("Start")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(startDisabled ? Color.textTertiary : Color.accent)
                            .padding(.horizontal, .spacingMd)
                            .padding(.vertical, .spacingXs)
                            .background(startDisabled ? Color.bgCardHover : Color.accentBg)
                            .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
                    }
                    .buttonStyle(.plain)
                    .disabled(startDisabled)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.spacingBase)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.borderSubtle)

            VStack(spacing: 0) {
                ForEach(exercises) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if let typeName = exercise.typeName {
                            Text(typeName)
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    .padding(.horizontal, .spacingBase)
                    .padding(.vertical, .spacingSm)
                }
            }

            Divider()
                .background(Color.borderSubtle)

            HStack(spacing: .spacingSm) {
                if let onViewDetail {
                    Button {
                        onViewDetail()
                    } label: {
                        Label("Details", systemImage: "chevron.right")
                    }
                    .foregroundStyle(Color.accent)
                }

                Spacer()

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .foregroundStyle(Color.textSecondary)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundStyle(Color.destructive)
            }
            .font(.subheadline.weight(.medium))
            .buttonStyle(.plain)
            .padding(.horizontal, .spacingBase)
            .padding(.vertical, .spacingSm)
        }
        .transition(.opacity)
    }

}

// MARK: - Card Style Modifier

private struct CardStyleModifier: ViewModifier {
    let style: TemplateCard.Style

    func body(content: Content) -> some View {
        switch style {
        case .card:
            content
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusLg)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
        case .listRow:
            content
        }
    }
}
