import SwiftUI

@MainActor
struct HistoryCalendarSheet: View {
    @State var viewModel: HistoryCalendarViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                    .padding(.top, .spacingSm)
                    .padding(.bottom, .spacingMd)

                weekdayHeader
                    .padding(.bottom, .spacingXs)

                if viewModel.isCollapsed {
                    weekStrip
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    monthGrid
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                collapseButton
                    .padding(.bottom, .spacingBase)
            }
            .padding(.horizontal, .spacingBase)
            .background(Color.bgSheet)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accent)
                }
            }
            .task { await viewModel.loadWorkoutDays() }
            .errorAlert(errorMessage: $viewModel.errorMessage)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accent)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(viewModel.monthYearString)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                viewModel.goToToday()
            } label: {
                Text("Today")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accent)
            }

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accent)
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(viewModel.weekdayLabels, id: \.self) { label in
                Text(label.prefix(1))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: .spacingXs) {
            ForEach(0..<viewModel.prefixPadding, id: \.self) { _ in
                Color.clear
                    .frame(height: 44)
            }

            ForEach(viewModel.daysInMonth, id: \.self) { date in
                dayCell(for: date)
            }
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        LazyVGrid(columns: columns, spacing: .spacingXs) {
            ForEach(viewModel.currentWeekDays, id: \.self) { date in
                dayCell(for: date)
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(for date: Date) -> some View {
        VStack(spacing: .spacing2xs) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: viewModel.isToday(date) ? .bold : .regular))
                .foregroundStyle(dayCellColor(for: date))

            if viewModel.hasWorkout(on: date) {
                Circle()
                    .fill(Color.accent)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 44)
    }

    private func dayCellColor(for date: Date) -> Color {
        if viewModel.isToday(date) {
            return .accent
        } else if viewModel.isInDisplayedMonth(date) {
            return .textPrimary
        } else {
            return .textTertiary
        }
    }

    // MARK: - Collapse Button

    private var collapseButton: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.toggleCollapsed()
            }
        } label: {
            Image(systemName: viewModel.isCollapsed ? "chevron.down" : "chevron.up")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 48, height: 28)
                .background(Color.bgCard)
                .clipShape(Capsule())
        }
    }
}
