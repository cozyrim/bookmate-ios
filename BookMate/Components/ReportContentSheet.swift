//
//  ReportContentSheet.swift
//  BookMate
//
//  Created by Codex on 6/20/26.
//

import SwiftUI

struct ReportContentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let target: ModerationTarget
    let moderationService: ModerationAPIService
    let onSubmitted: (ModerationReportEnvelope) -> Void

    @State private var selectedReason: ModerationReportReason = .inappropriateLanguage
    @State private var detail = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        targetSummary
                        reasonSection
                        detailSection

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color("Error"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        submitButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("신고하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color("TextSecondary"))
                }
            }
        }
    }

    private var targetSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(target.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            Text(target.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color("TextSecondary"))
                .lineLimit(2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface").opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("신고 사유")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            VStack(spacing: 10) {
                ForEach(ModerationReportReason.allCases) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedReason == reason ? Color("Primary") : Color("TextMuted"))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(reason.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color("TextPrimary"))

                                Text(reason.description)
                                    .font(.caption)
                                    .foregroundStyle(Color("TextSecondary"))
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .background(
                            selectedReason == reason
                            ? Color("PrimarySoft").opacity(0.66)
                            : Color("Surface").opacity(0.74),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 내용")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("TextPrimary"))

            TextEditor(text: $detail)
                .frame(minHeight: 96)
                .scrollContentBackground(.hidden)
                .padding(14)
                .background(Color("Surface").opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if detail.isEmpty {
                        Text("운영자가 확인할 수 있도록 내용을 적어주세요. 선택 사항이에요.")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextMuted"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(Color("PrimaryButtonText"))
                }

                Text(isSubmitting ? "접수 중" : "신고 접수")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(Color("PrimaryButtonText"))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color("Primary"), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.7 : 1)
    }

    private func submit() {
        guard !isSubmitting else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let result = try await moderationService.submitReport(
                    target: target,
                    reason: selectedReason,
                    detail: detail
                )

                await MainActor.run {
                    onSubmitted(result)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "신고 접수에 실패했어요. 잠시 후 다시 시도해주세요."
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    ReportContentSheet(
        target: ModerationTarget(
            targetType: .guestbookMessage,
            targetId: UUID().uuidString,
            targetUserId: UUID(),
            title: "방명록 신고",
            subtitle: "부적절한 방명록 내용을 신고합니다.",
            snapshot: ["content": "예시 방명록"]
        ),
        moderationService: ModerationAPIService(),
        onSubmitted: { _ in }
    )
}
