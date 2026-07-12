//
//  FeedbackView.swift
//  BookMate
//
//  Created by 한채림 on 7/12/26.
//

import SwiftUI
import StoreKit
import MessageUI
import UIKit

struct FeedbackView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var isShowingMailComposer = false
    @State private var isShowingMailErrorAlert = false
    @State private var toast: AppToast?

    private static let recipientEmail = "cozyriming@gmail.com"
    private static let mailSubject = "북메이트 피드백"

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 24) {
                SettingsScreenHeader(title: "피드백 남기기")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        feedbackHeader

                        SettingsSectionCard(title: "의견 보내기") {
                            SettingsNavigationRow(
                                iconName: "envelope",
                                title: "메일로 피드백 보내기",
                                value: "작성"
                            ) {
                                composeFeedbackEmail()
                            }
                        }

                        SettingsSectionCard(title: "앱 평가") {
                            SettingsNavigationRow(
                                iconName: "star",
                                title: "앱 평가하기",
                                value: "열기"
                            ) {
                                requestAppReview()
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBackGesture()
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $isShowingMailComposer) {
            MailComposerView(
                recipient: Self.recipientEmail,
                subject: Self.mailSubject,
                body: emailBody
            ) { result, error in
                handleMailComposeResult(result, error: error)
            }
        }
        .alert("메일 앱을 열 수 없어요", isPresented: $isShowingMailErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("기기에서 메일 계정을 확인한 뒤 다시 시도해 주세요.")
        }
        .appToast($toast)
    }

    private var feedbackHeader: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color("PrimaryDeep"))
                .frame(width: 76, height: 76)
                .background(Color("Primary").opacity(0.16))
                .clipShape(Circle())

            VStack(spacing: 6) {
                Text("북메이트에게 전하고 싶은 말")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("불편했던 점이나 바라는 점을 편하게 남겨주세요.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }

    private var emailBody: String {
        """
        안녕하세요.
        북메이트에 남기고 싶은 피드백을 적어주세요.


        ---
        앱 버전: \(appVersion)
        기기: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        """
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.recipientEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: Self.mailSubject),
            URLQueryItem(name: "body", value: emailBody)
        ]
        return components.url
    }

    private func composeFeedbackEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            openFallbackMailURL()
            return
        }

        isShowingMailComposer = true
    }

    private func openFallbackMailURL() {
        guard let mailtoURL else {
            isShowingMailErrorAlert = true
            return
        }

        openURL(mailtoURL) { accepted in
            if !accepted {
                isShowingMailErrorAlert = true
            }
        }
    }

    private func requestAppReview() {
        requestReview()
    }

    private func handleMailComposeResult(_ result: MFMailComposeResult, error: Error?) {
        if error != nil {
            toast = AppToast(message: "메일 작성 중 문제가 생겼어요.", style: .error)
            return
        }

        switch result {
        case .sent:
            toast = AppToast(message: "피드백 메일을 보냈어요.", style: .success)
        case .saved:
            toast = AppToast(message: "메일을 임시 저장했어요.", style: .info)
        case .failed:
            toast = AppToast(message: "메일을 보내지 못했어요.", style: .error)
        case .cancelled:
            break
        @unknown default:
            break
        }
    }
}

private struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let recipient: String
    let subject: String
    let body: String
    let onFinish: (MFMailComposeResult, Error?) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let parent: MailComposerView

        init(parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            parent.onFinish(result, error)
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}
