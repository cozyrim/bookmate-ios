//
//  MainTabView.swift
//  BookMate
//
//  Created by 한채림 on 5/11/26.
//

import Combine
import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject var authViewModel: AuthSessionViewModel
    @StateObject private var viewModel: BookMateViewModel
    @ObservedObject private var pushNotificationRouter = PushNotificationRouter.shared
    @State var tabIndex = 0
    @State private var hidesCompactBar = false
    @State private var keyboardIsPresented = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var roomNotificationRequest: PushNotificationNavigationRequest?
    @State private var notificationPermissionDialog: NotificationPermissionDialog?

    init(authViewModel: AuthSessionViewModel, dependencies: AppDependencies? = nil) {
        self.authViewModel = authViewModel
        _viewModel = StateObject(wrappedValue: BookMateViewModel(dependencies: dependencies))
    }

    var body: some View {
        TabView(selection: $tabIndex) {
            Tab(value: 0) {
                HomeView(viewModel: viewModel, selectedTab: $tabIndex)
                    .modifier(ScrollingTabBarModifier())
            } label: {
                tabLabel("홈", icon: Image(systemName: "house"))
            }
            .accessibilityLabel("홈")

            Tab(value: 1) {
                ShelfView(viewModel: viewModel, selectedTab: $tabIndex)
                    .modifier(ScrollingTabBarModifier())
            } label: {
                tabLabel("책", icon: Image(systemName: "book"))
            }
            .accessibilityLabel("책")

            Tab(value: 2) {
                WordArchiveView(viewModel: viewModel, selectedTab: $tabIndex)
                    .modifier(ScrollingTabBarModifier())
            } label: {
                tabLabel("단어장", icon: Image("TabWordIcon").renderingMode(.template))
            }
            .accessibilityLabel("단어장")

            Tab(value: 3) {
                RoomTabView(viewModel: viewModel, notificationRequest: $roomNotificationRequest)
                    .modifier(ScrollingTabBarModifier())
            } label: {
                tabLabel("서재", icon: Image(systemName: "books.vertical"))
            }
            .accessibilityLabel("서재")

            Tab(value: 4) {
                ProfileView(authViewModel: authViewModel, viewModel: viewModel)
                    .modifier(ScrollingTabBarModifier())
            } label: {
                tabLabel("프로필", icon: Image(systemName: "person.crop.circle"))
            }
            .accessibilityLabel("프로필")
        }
        .toolbar(UIDevice.current.userInterfaceIdiom == .phone ? .hidden : .automatic, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if UIDevice.current.userInterfaceIdiom == .phone && !hidesCompactBar && !keyboardIsPresented {
                CompactTabBar(selection: $tabIndex)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardIsPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardIsPresented = false
        }
        .onPreferenceChange(CompactTabBarHiddenKey.self) { hidesCompactBar = $0 }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: hidesCompactBar)
        .tint(Color("Primary"))
        .appToast($viewModel.toast) // MainTabView가 가진 viewModel.toast 값을 AppToastModifier에게 연결해서 넘긴다.원본 값을 읽고 바꿀 수 있는 연결 통로 전달
        .onAppear {
            BMAnalytics.screenView(screen(for: tabIndex))

            if let request = pushNotificationRouter.pendingRequest {
                handleNotificationNavigation(request)
            }
        }
        .onReceive(pushNotificationRouter.$pendingRequest.compactMap { $0 }) { request in
            handleNotificationNavigation(request)
        }
        .task(id: authViewModel.currentUser?.id) {
            viewModel.setCurrentUser(authViewModel.currentUser) // 로그인한 사용자마다 최근 검색어 저장칸이 다름
            BMAnalytics.setUser(authViewModel.currentUser)

            await viewModel.loadBooks()
            await viewModel.loadSavedWords()
        }
        .task(id: authViewModel.shouldRequestNotificationPermissionAfterSignup) {
            presentPostSignupNotificationPermissionIfNeeded()
        }
        .overlay {
            if notificationPermissionDialog != nil {
                PostSignupNotificationPermissionDialog(
                    onRequestPermission: requestNotificationPermissionFromDialog,
                    onDismiss: dismissNotificationPermissionDialog
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.18), value: notificationPermissionDialog?.id)
        .onChange(of: tabIndex) { _, newValue in
            BMAnalytics.tabTap(index: newValue, name: tabName(for: newValue))
            BMAnalytics.screenView(screen(for: newValue))

            guard newValue == 0 else { return }
            viewModel.clearSearchState(searchMode: .dictionary)
        }
        .onChange(of: viewModel.didReceiveUnauthorized) { _, expired in
            guard expired else { return }
            authViewModel.logout()
            viewModel.didReceiveUnauthorized = false
        } // 401이 오면 자동으로 로그아웃되고 로그인 화면으로 돌아감


    }

    @ViewBuilder
    private func tabLabel(_ title: LocalizedStringKey, icon: Image) -> some View {
        if UIDevice.current.userInterfaceIdiom != .phone && horizontalSizeClass == .regular {
            Label {
                Text(title)
            } icon: {
                icon
            }
        } else {
            icon
        }
    }

    private func tabName(for index: Int) -> String {
        switch index {
        case 0:
            return "home"
        case 1:
            return "book_shelf"
        case 2:
            return "word_archive"
        case 3:
            return "library"
        case 4:
            return "profile"
        default:
            return "unknown"
        }
    }

    private func screen(for index: Int) -> BMAnalytics.Screen {
        switch index {
        case 1:
            return .bookShelf
        case 2:
            return .wordArchive
        case 3:
            return .library
        case 4:
            return .profile
        default:
            return .home
        }
    }

    private func handleNotificationNavigation(_ request: PushNotificationNavigationRequest) {
        switch request.destination {
        case .myGuestbook:
            tabIndex = 3
            roomNotificationRequest = request
            pushNotificationRouter.consume(request)
        }
    }

    private func presentPostSignupNotificationPermissionIfNeeded() {
        guard authViewModel.shouldRequestNotificationPermissionAfterSignup else {
            return
        }

        authViewModel.shouldRequestNotificationPermissionAfterSignup = false
        notificationPermissionDialog = .postSignup
    }

    private func requestNotificationPermissionFromDialog() {
        notificationPermissionDialog = nil

        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            await PushNotificationService.shared.requestAuthorizationAndRegisterForRemoteNotifications()
        }
    }

    private func dismissNotificationPermissionDialog() {
        notificationPermissionDialog = nil
    }
}

private enum NotificationPermissionDialog: Identifiable {
    case postSignup

    var id: String {
        switch self {
        case .postSignup:
            return "post-signup-notification-permission"
        }
    }
}

private struct PostSignupNotificationPermissionDialog: View {
    let onRequestPermission: () -> Void
    let onDismiss: () -> Void
    @State private var isRequestingPermission = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color("PrimaryDeep"))
                    .frame(width: 68, height: 68)
                    .background(Color("Primary").opacity(0.16), in: Circle())

                VStack(spacing: 10) {
                    Text("내 서재 소식을 놓치지 않게")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))
                        .multilineTextAlignment(.center)

                    Text("방명록이 도착하거나 읽던 책을 다시 펼칠 시간이 되면 북메이트가 알려드려요.")
                        .font(.callout)
                        .foregroundStyle(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    NotificationPermissionBenefitRow(
                        iconName: "heart.text.square",
                        title: "방명록 알림",
                        description: "누군가 내 서재에 글을 남기면 바로 확인할 수 있어요."
                    )

                    NotificationPermissionBenefitRow(
                        iconName: "book.closed",
                        title: "독서 리마인드",
                        description: "읽던 책을 이어갈 시간을 놓치지 않게 도와드려요."
                    )
                }

                VStack(spacing: 10) {
                    Button {
                        requestPermission()
                    } label: {
                        Text(isRequestingPermission ? "확인 중..." : "알림 받기")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("PrimaryButtonText"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color("Primary"), in: Capsule())
                    }
                    .disabled(isRequestingPermission)
                    .opacity(isRequestingPermission ? 0.72 : 1)

                    Button {
                        onDismiss()
                    } label: {
                        Text("나중에")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("TextSecondary"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .disabled(isRequestingPermission)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: 340)
            .background(Color("AppBackground"), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color("Surface").opacity(0.82), lineWidth: 1)
            }
            .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .contain)
    }

    private func requestPermission() {
        guard !isRequestingPermission else { return }

        isRequestingPermission = true
        onRequestPermission()
    }
}

private struct NotificationPermissionBenefitRow: View {
    let iconName: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color("PrimaryDeep"))
                .frame(width: 40, height: 40)
                .background(Color("Primary").opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary").opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color("Surface").opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    MainTabView(authViewModel: AuthSessionViewModel())
}
