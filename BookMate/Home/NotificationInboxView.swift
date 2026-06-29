//
//  NotificationInboxView.swift
//  BookMate
//
//  Created by Codex on 6/29/26.
//

import SwiftUI

struct NotificationInboxView: View {
    @ObservedObject var viewModel: BookMateViewModel
    let onClose: (() -> Void)?
    let onSelect: (AppNotificationItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [AppNotificationItem] = []
    @State private var isLoading = false
    @State private var isShowingNotificationSettings = false
    @State private var toast: AppToast?
    @State private var refreshFailureMessage: String?

    private let notificationService = NotificationAPIService()

    private var unreadNotifications: [AppNotificationItem] {
        notifications.filter { !$0.isRead }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")

                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let refreshFailureMessage {
                        refreshFailureBanner(refreshFailureMessage)
                    }

                    if isLoading && notifications.isEmpty {
                        loadingState
                    } else if notifications.isEmpty {
                        emptyState
                    } else {
                        notificationList
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .appToast($toast)
            .task {
                await loadNotifications()
            }
            .sheet(isPresented: $isShowingNotificationSettings) {
                NotificationSettingsView(viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("알림")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text(unreadNotifications.isEmpty ? "새 알림이 없어요." : "\(unreadNotifications.count)개의 새 알림이 있어요.")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer()

            Button {
                isShowingNotificationSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 38, height: 38)
                    .background(Color("Surface").opacity(0.92), in: Circle())
            }
            .accessibilityLabel("알림 설정")

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 38, height: 38)
                    .background(Color("Surface").opacity(0.92), in: Circle())
            }
            .accessibilityLabel("닫기")
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color("Primary"))

            Text("알림을 불러오는 중이에요.")
                .font(.callout)
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func refreshFailureBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 13, weight: .semibold))

            Text(message)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .foregroundStyle(Color("TextSecondary"))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color("Surface").opacity(0.72), in: Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color("Primary"))
                .frame(width: 58, height: 58)
                .background(Color("Primary").opacity(0.12), in: Circle())

            VStack(spacing: 5) {
                Text("도착한 알림이 없어요")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("방명록과 서재 소식이 생기면 여기에서 확인할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if !unreadNotifications.isEmpty {
                    markAllReadButton
                }

                ForEach(notifications) { notification in
                    notificationRow(notification)
                }
            }
            .padding(.bottom, 18)
        }
        .refreshable {
            await loadNotifications()
        }
    }

    private var markAllReadButton: some View {
        HStack {
            Spacer()

            Button {
                Task {
                    await markAllRead()
                }
            } label: {
                Text("모두 읽음")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextSecondary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Surface").opacity(0.85), in: Capsule())
            }
        }
    }

    private func notificationRow(_ notification: AppNotificationItem) -> some View {
        Button {
            Task {
                await open(notification)
            }
        } label: {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: iconName(for: notification))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("Primary"))
                    .frame(width: 38, height: 38)
                    .background(Color("Primary").opacity(notification.isRead ? 0.08 : 0.15), in: Circle())

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(notification.title)
                            .font(.callout)
                            .fontWeight(notification.isRead ? .semibold : .bold)
                            .foregroundStyle(Color("TextPrimary"))
                            .lineLimit(2)

                        if !notification.isRead {
                            Circle()
                                .fill(Color("Primary"))
                                .frame(width: 7, height: 7)
                        }
                    }

                    Text(notification.body)
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                        .lineLimit(2)

                    Text(notification.createdAtText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("TextSecondary").opacity(0.72))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Surface").opacity(notification.isRead ? 0.82 : 0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color("Border").opacity(notification.isRead ? 0.18 : 0.32), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func iconName(for notification: AppNotificationItem) -> String {
        switch notification.type {
        case "guestbook_message":
            return "text.bubble"
        default:
            return "bell"
        }
    }

    @MainActor
    private func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }

        do {
            notifications = try await notificationService.fetchNotifications()
            refreshFailureMessage = nil
        } catch {
            DebugLogger.log("알림 목록 로드 실패:", error)

            if let apiError = error as? APIError,
               case .unauthorized = apiError {
                viewModel.didReceiveUnauthorized = true
            }

            if notifications.isEmpty {
                refreshFailureMessage = nil
                toast = AppToast(
                    message: error.bookMateUserMessage(fallback: "알림을 불러오지 못했어요."),
                    style: .error
                )
            } else {
                refreshFailureMessage = error.bookMateUserMessage(fallback: "최신 알림을 확인하지 못했어요.")
            }
        }
    }

    @MainActor
    private func open(_ notification: AppNotificationItem) async {
        do {
            if !notification.isRead {
                try await notificationService.markNotificationRead(id: notification.id)
                markReadLocally(notification.id)
            }
            refreshFailureMessage = nil

            close()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSelect(notification)
            }
        } catch {
            toast = AppToast(
                message: error.bookMateUserMessage(fallback: "알림을 열지 못했어요."),
                style: .error
            )
        }
    }

    @MainActor
    private func markAllRead() async {
        do {
            try await notificationService.markAllNotificationsRead()
            refreshFailureMessage = nil
            notifications = notifications.map { notification in
                AppNotificationItem(
                    id: notification.id,
                    type: notification.type,
                    title: notification.title,
                    body: notification.body,
                    data: notification.data,
                    isRead: true,
                    createdAt: notification.createdAt,
                    readAt: notification.readAt
                )
            }
        } catch {
            toast = AppToast(
                message: error.bookMateUserMessage(fallback: "알림 상태를 바꾸지 못했어요."),
                style: .error
            )
        }
    }

    private func markReadLocally(_ id: UUID) {
        notifications = notifications.map { notification in
            guard notification.id == id else { return notification }

            return AppNotificationItem(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                isRead: true,
                createdAt: notification.createdAt,
                readAt: notification.readAt
            )
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview {
    NotificationInboxView(viewModel: BookMateViewModel(), onClose: nil) { _ in }
}
