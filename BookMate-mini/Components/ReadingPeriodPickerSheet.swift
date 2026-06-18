import SwiftUI

struct ReadingPeriodPickerSheet: View {
    private enum PeriodTarget: String, CaseIterable, Identifiable {
        case start = "시작일"
        case end = "종료일"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var selectedTarget: PeriodTarget = .start
    @State private var draftStartDate: Date
    @State private var draftEndDate: Date

    init(startDate: Binding<Date?>, endDate: Binding<Date?>) {
        _startDate = startDate
        _endDate = endDate
        _draftStartDate = State(initialValue: startDate.wrappedValue ?? Date())
        _draftEndDate = State(initialValue: endDate.wrappedValue ?? startDate.wrappedValue ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("날짜 종류", selection: $selectedTarget) {
                    ForEach(PeriodTarget.allCases) { target in
                        Text(target.rawValue).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    periodPreview(title: "시작일", date: draftStartDate, isSelected: selectedTarget == .start) {
                        selectedTarget = .start
                    }

                    periodPreview(title: "종료일", date: draftEndDate, isSelected: selectedTarget == .end) {
                        selectedTarget = .end
                    }
                }

                if selectedTarget == .start {
                    DatePicker(
                        "시작일",
                        selection: $draftStartDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .onChange(of: draftStartDate) { _, newValue in
                        if draftEndDate < newValue {
                            draftEndDate = newValue
                        }
                    }
                } else {
                    DatePicker(
                        "종료일",
                        selection: $draftEndDate,
                        in: draftStartDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }

                Button {
                    startDate = draftStartDate
                    endDate = draftEndDate
                    dismiss()
                } label: {
                    Text("기간 선택 완료")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("Primary"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(24)
            .navigationTitle("읽은 기간")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button("초기화") {
                        startDate = nil
                        endDate = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private func periodPreview(
        title: String,
        date: Date,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color("TextMuted"))

                Text(BookMateDateFormatter.display.string(from: date))
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Color("Primary") : Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
