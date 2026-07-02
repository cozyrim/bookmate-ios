//
//  OnboardingView.swift
//  BookMate
//
//  Created by Codex on 6/20/26.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var selectedPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                topBar

                TabView(selection: $selectedPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomControls
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 22)
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color("PrimarySoft").opacity(0.76), location: 0.00),
                    .init(color: Color("AppBackgroundSoft").opacity(0.96), location: 0.48),
                    .init(color: Color("AppBackground").opacity(0.99), location: 1.00)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color("Primary").opacity(0.12),
                    Color.clear,
                    Color("Surface").opacity(0.30)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    selectedPage = max(0, selectedPage - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .opacity(selectedPage == 0 ? 0 : 1)
            .disabled(selectedPage == 0)

            Spacer()

            Button("건너뛰기") {
                onFinish()
            }
            .font(.callout.weight(.bold))
            .foregroundStyle(Color("TextSecondary"))
            .buttonStyle(.plain)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 22) {
            pageIndicator

            Button {
                if selectedPage == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation(.easeOut(duration: 0.18)) {
                        selectedPage += 1
                    }
                }
            } label: {
                Text(selectedPage == pages.count - 1 ? "시작하기" : "다음으로")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color("PrimaryButtonText"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("Primary"), in: Capsule())
                .shadow(color: Color("Shadow").opacity(0.12), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedPage ? Color("Primary") : Color("TextMuted").opacity(0.22))
                    .frame(width: index == selectedPage ? 34 : 8, height: 8)
            }
        }
        .frame(height: 10)
        .animation(.easeOut(duration: 0.18), value: selectedPage)
        .accessibilityLabel("\(selectedPage + 1)번째 온보딩")
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        switch page.layout {
        case .legacy:
            LegacyOnboardingPageView(page: page)
        case .feature:
            FeatureOnboardingPageView(page: page)
        }
    }
}

private struct LegacyOnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            OnboardingTopSpacer()

            OnboardingCopyBlock(page: page)

            switch page.visual {
            case .book:
                OnboardingImageCard(imageName: "OnboardingBookBlue")
            case .dictionary:
                DictionarySearchIllustration()
            case .room:
                OnboardingImageCard(imageName: "OnboardingRoomBlue")
            case .waveGuestbook, .review, .notification:
                EmptyView()
            }

            Spacer(minLength: 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(page.accessibilityLabel)
    }
}

private struct FeatureOnboardingPageView: View {
    let page: OnboardingPage

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { proxy in
            let usesRegularReviewVisual = horizontalSizeClass == .regular && page.visual == .review
            let usesRegularFeatureVisual = horizontalSizeClass == .regular
                && (page.visual == .review || page.visual == .notification)
            let usesTallCompactReviewVisual = horizontalSizeClass != .regular
                && page.visual == .review
                && proxy.size.height > 1_000
            let maxImageWidth = usesRegularFeatureVisual ? CGFloat(440) : CGFloat(324)
            let maxImageHeight = usesRegularReviewVisual ? CGFloat(580) : (usesRegularFeatureVisual ? CGFloat(530) : CGFloat(430))
            let imageHeightRatio = usesRegularReviewVisual ? CGFloat(0.76) : (usesRegularFeatureVisual ? CGFloat(0.72) : CGFloat(0.58))
            let imageWidth = min(proxy.size.width, maxImageWidth)
            let imageHeight = min(max(proxy.size.height * imageHeightRatio, 330), maxImageHeight)
            let visualYOffset = (usesRegularReviewVisual || usesTallCompactReviewVisual) ? CGFloat(-22) : CGFloat(0)

            VStack(spacing: 24) {
                OnboardingTopSpacer(compactFixedHeight: usesTallCompactReviewVisual ? 78 : nil)

                OnboardingCopyBlock(page: page)

                OnboardingVisualView(
                    visual: page.visual,
                    imageWidth: imageWidth,
                    imageHeight: imageHeight
                )
                .offset(y: visualYOffset)
                .accessibilityHidden(true)

                Spacer(minLength: 12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(page.accessibilityLabel)
    }
}

private struct OnboardingTopSpacer: View {
    var compactFixedHeight: CGFloat? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            Color.clear
                .frame(height: 198)
        } else if let compactFixedHeight {
            Color.clear
                .frame(height: compactFixedHeight)
        } else {
            Spacer(minLength: 36)
        }
    }
}

private struct OnboardingCopyBlock: View {
    let page: OnboardingPage

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(page.title)
                .font(.system(size: 29, weight: .heavy))
                .foregroundStyle(page.titleColor)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(page.subtitle)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: horizontalSizeClass == .regular ? 152 : nil, alignment: .topLeading)
    }
}

private struct OnboardingVisualView: View {
    let visual: OnboardingPage.Visual
    let imageWidth: CGFloat
    let imageHeight: CGFloat

    var body: some View {
        switch visual {
        case .waveGuestbook:
            Image("OnboardingWaveGuestbook")
                .resizable()
                .scaledToFill()
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color("Surface").opacity(0.28), lineWidth: 1)
                }
                .shadow(color: Color("Shadow").opacity(0.16), radius: 24, y: 12)
        case .review:
            ReviewOnboardingVisual(width: imageWidth, height: imageHeight)
        case .notification:
            NotificationOnboardingVisual(width: imageWidth, height: imageHeight)
        case .book, .dictionary, .room:
            EmptyView()
        }
    }
}

private struct OnboardingImageCard: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 286, height: 286)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color("Surface").opacity(0.45), lineWidth: 1)
            }
            .shadow(color: Color("Shadow").opacity(0.10), radius: 20, y: 9)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
    }
}

private struct DictionarySearchIllustration: View {
    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.headline.weight(.semibold))
                Text("사무치다")
                    .font(.headline.weight(.semibold))
                Spacer()
                Image(systemName: "xmark.circle")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(Color("TextSecondary"))
            .padding(.horizontal, 22)
            .frame(height: 56)
            .background(Color("SurfaceElevated").opacity(0.58), in: Capsule())

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("사무치다")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Color("TextPrimary"))
                        Text("동사")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("TextSecondary"))
                    }

                    Spacer()

                    Label("저장", systemImage: "bookmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("PrimaryDeep"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color("SurfaceElevated").opacity(0.46), in: Capsule())
                }

                Divider()
                    .overlay(Color("Border").opacity(0.18))

                Text("1. 깊이 스며들거나 빠져들게 느껴지다.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\"그의 슬픔이 가슴에 사무쳤다.\"")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
            .background(Color("PrimarySoft").opacity(0.56), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .padding(22)
        .frame(height: 300)
        .background(Color("Surface").opacity(0.78), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color("Surface").opacity(0.34), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.045), radius: 18, y: 8)
        .padding(.top, 18)
    }
}

private struct ReviewOnboardingVisual: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let width: CGFloat
    let height: CGFloat

    var body: some View {
        if horizontalSizeClass == .regular {
            OnboardingIPadReviewVisual(width: width, height: height)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color("Surface").opacity(0.46))
                    .frame(width: width * 0.92, height: height * 0.84)
                    .offset(y: 12)

                OnboardingScreenshotCard(
                    imageName: "OnboardingReviewList",
                    width: width * 0.68,
                    height: height * 0.78,
                    cornerRadius: 30,
                    alignment: .top
                )
                .opacity(0.92)
                .offset(x: width * 0.08, y: -height * 0.08)

                OnboardingReviewQuoteCard(width: width * 0.86)
                    .offset(y: height * 0.30)

                HStack(spacing: 7) {
                    Image(systemName: "star.fill")
                        .font(.caption.weight(.bold))
                    Text("공개 후기")
                        .font(.caption.weight(.heavy))
                }
                .foregroundStyle(Color("PrimaryDeep"))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color("Surface").opacity(0.90), in: Capsule())
                .shadow(color: Color("Shadow").opacity(0.12), radius: 12, y: 6)
                .offset(x: -width * 0.27, y: -height * 0.30)
            }
            .frame(width: width, height: height)
        }
    }
}

private struct OnboardingIPadReviewVisual: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color("Surface").opacity(0.46))
                .frame(width: width * 0.92, height: height * 0.84)
                .offset(y: 12)

            OnboardingIPadReviewScreenshotCard(
                width: width * 0.90,
                height: height * 0.82
            )
            .opacity(0.92)
            .offset(x: width * 0.03, y: -height * 0.04)

            OnboardingReviewQuoteCard(width: width * 0.92)
                .offset(y: height * 0.27)

            HStack(spacing: 7) {
                Image(systemName: "star.fill")
                    .font(.caption.weight(.bold))
                Text("공개 후기")
                    .font(.caption.weight(.heavy))
            }
            .foregroundStyle(Color("PrimaryDeep"))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color("Surface").opacity(0.90), in: Capsule())
            .shadow(color: Color("Shadow").opacity(0.12), radius: 12, y: 6)
            .offset(x: -width * 0.25, y: -height * 0.25)
        }
        .frame(width: width, height: height)
    }
}

private struct OnboardingIPadReviewScreenshotCard: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color("Surface").opacity(0.86))

            Image("OnboardingReviewListIPad")
                .resizable()
                .scaledToFit()
                .frame(width: width * 1.04)
                .frame(width: width, height: height, alignment: .top)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color("Primary").opacity(0.12), lineWidth: 1.2)
        }
        .shadow(color: Color("Shadow").opacity(0.16), radius: 20, y: 10)
    }
}

private struct OnboardingReviewQuoteCard: View {
    let width: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color("PrimarySoft").opacity(0.82))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("PrimaryDeep").opacity(0.74))
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2.weight(.bold))
                    }
                }
                .foregroundStyle(Color("Primary"))

                Text("꿈을 향해 나아가는 여정을 쉽고 따뜻하게 풀어낸 책이에요.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("TextPrimary"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("책 검색에서 보이는 공개 후기")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("TextSecondary"))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(width: width)
        .background(Color("Surface").opacity(0.96), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color("Surface").opacity(0.52), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.13), radius: 16, y: 8)
    }
}

private struct NotificationOnboardingVisual: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(spacing: 12) {
            OnboardingScreenshotCard(
                imageName: settingsImageName,
                width: settingsImageWidth,
                height: settingsImageHeight,
                cornerRadius: horizontalSizeClass == .regular ? 32 : 30,
                alignment: .top
            )

            VStack(spacing: 8) {
                OnboardingBannerImage(
                    imageName: "OnboardingNotificationReadingBanner",
                    width: horizontalSizeClass == .regular ? width * 0.74 : width * 0.82
                )

                OnboardingBannerImage(
                    imageName: "OnboardingNotificationGuestbookBanner",
                    width: horizontalSizeClass == .regular ? width * 0.78 : width * 0.86
                )
            }
        }
        .frame(width: width, height: height)
    }

    private var settingsImageName: String {
        horizontalSizeClass == .regular
            ? "OnboardingNotificationSettingsIPad"
            : "OnboardingNotificationSettingsScreen"
    }

    private var settingsImageWidth: CGFloat {
        horizontalSizeClass == .regular ? width * 0.72 : width * 0.74
    }

    private var settingsImageHeight: CGFloat {
        horizontalSizeClass == .regular ? height * 0.72 : height * 0.58
    }
}

private struct OnboardingScreenshotCard: View {
    let imageName: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    var alignment: Alignment = .center

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height, alignment: alignment)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color("Surface").opacity(0.38), lineWidth: 1)
            }
            .shadow(color: Color("Shadow").opacity(0.16), radius: 18, y: 10)
    }
}

private struct OnboardingBannerImage: View {
    let imageName: String
    let width: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .shadow(color: Color("Shadow").opacity(0.14), radius: 12, y: 6)
    }
}

private struct OnboardingPage: Identifiable {
    enum Visual {
        case book
        case dictionary
        case room
        case waveGuestbook
        case review
        case notification
    }

    enum Layout {
        case legacy
        case feature
    }

    let id: String
    let title: String
    let subtitle: String
    let titleColor: Color
    let layout: Layout
    let visual: Visual
    let accessibilityLabel: String

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: "remember",
            title: "책에서 만난 단어를,\n잊지 않게.",
            subtitle: "읽다가 멈추지 마세요.\n북메이트가 기억해드릴게요.",
            titleColor: Color("Primary"),
            layout: .legacy,
            visual: .book,
            accessibilityLabel: "책에서 만난 단어를 잊지 않게. 읽다가 멈추지 마세요. 북메이트가 기억해드릴게요."
        ),
        OnboardingPage(
            id: "search",
            title: "모르는 단어,\n바로 검색하세요.",
            subtitle: "책을 읽다 막히는 순간,\n뜻을 찾고 단어장에 기록해보세요.",
            titleColor: Color("TextPrimary"),
            layout: .legacy,
            visual: .dictionary,
            accessibilityLabel: "모르는 단어, 바로 검색하세요. 책을 읽다 막히는 순간 뜻을 찾고 단어장에 기록해보세요."
        ),
        OnboardingPage(
            id: "room",
            title: "서재에서\n독서 기록을 모아보세요.",
            subtitle: "읽은 책과 저장한 단어가\n나만의 공간에 차곡차곡 쌓여요.",
            titleColor: Color("Primary"),
            layout: .legacy,
            visual: .room,
            accessibilityLabel: "서재에서 독서 기록을 모아보세요. 읽은 책과 저장한 단어가 나만의 공간에 차곡차곡 쌓여요."
        ),
        OnboardingPage(
            id: "waveGuestbook",
            title: "파도타기 / 방명록",
            subtitle: "다른 사람의 서재를 타고\n새로운 책을 발견해요",
            titleColor: Color("TextPrimary"),
            layout: .feature,
            visual: .waveGuestbook,
            accessibilityLabel: "파도타기와 방명록. 다른 사람의 서재를 타고 새로운 책을 발견해요."
        ),
        OnboardingPage(
            id: "reviewSearch",
            title: "내 감상이\n다음 독자에게 닿도록",
            subtitle: "완독 후 남긴 감상평을 공개하면\n책을 검색하는 사람도 볼 수 있어요",
            titleColor: Color("TextPrimary"),
            layout: .feature,
            visual: .review,
            accessibilityLabel: "내 감상이 다음 독자에게 닿도록. 완독 후 남긴 감상평을 공개하면 책을 검색하는 사람도 볼 수 있어요."
        ),
        OnboardingPage(
            id: "notificationSettings",
            title: "알림 설정",
            subtitle: "읽을 시간과 새 소식을\n놓치지 않게 알려드려요",
            titleColor: Color("TextPrimary"),
            layout: .feature,
            visual: .notification,
            accessibilityLabel: "알림 설정. 읽을 시간과 새 소식을 놓치지 않게 알려드려요."
        )
    ]
}

#Preview {
    OnboardingView(onFinish: {})
}
