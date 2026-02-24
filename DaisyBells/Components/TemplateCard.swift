import SwiftUI

@MainActor
struct TemplateCard: View {
    let name: String
    let exercises: [ExerciseInfo]
    let isExpanded: Bool
    let isPendingDelete: Bool
    let startDisabled: Bool?
    let onToggleExpand: () -> Void
    let onStart: (() -> Void)?
    let onEdit: () -> Void
    let onRequestDelete: () -> Void
    let onCancelDelete: () -> Void
    let onConfirmDelete: () -> Void
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

            if isExpanded && !isPendingDelete {
                expandedContent
            }
        }
        .modifier(CardStyleModifier(style: style))
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onRequestDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onRequestDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.destructive)
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.accent)
        }
    }

    // MARK: - Header

    private var headerButton: some View {
        Button {
            if !isPendingDelete {
                onToggleExpand()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isPendingDelete ? Color.textTertiary : Color.textPrimary)
                    Text("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(isPendingDelete ? Color.textTertiary : Color.textSecondary)
                }

                Spacer()

                if isPendingDelete {
                    deleteConfirmationButtons
                } else {
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
            }
            .padding(.spacingBase)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isPendingDelete ? 0.5 : 1.0)
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

            if let onViewDetail {
                Divider()
                    .background(Color.borderSubtle)

                Button {
                    onViewDetail()
                } label: {
                    HStack {
                        Text("View Details")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.accent)
                    }
                    .padding(.horizontal, .spacingBase)
                    .padding(.vertical, .spacingSm)
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Delete Confirmation

    private var deleteConfirmationButtons: some View {
        HStack(spacing: .spacingSm) {
            Button {
                onCancelDelete()
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, .spacingSm)
                    .padding(.vertical, .spacingXs)
                    .background(Color.bgCardHover)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
            }
            .buttonStyle(.plain)

            Button {
                onConfirmDelete()
            } label: {
                Text("Confirm")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, .spacingSm)
                    .padding(.vertical, .spacingXs)
                    .background(Color.destructive)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
            }
            .buttonStyle(.plain)
        }
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
