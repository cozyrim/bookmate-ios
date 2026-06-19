//
//  OnboardingView.swift
//  BookMate-mini
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
        VStack(spacing: 24) {
            Spacer(minLength: 36)

            VStack(alignment: .leading, spacing: 18) {
                Text(page.title)
                    .font(.system(size: 29, weight: .heavy))
                    .foregroundStyle(page.titleColor)
                    .lineLimit(3)
                    .minimumScaleFactor(0.84)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(page.subtitle)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            switch page.visual {
            case .book:
                OnboardingImageCard(
                    imageName: "OnboardingBookBlue"
                )
            case .dictionary:
                DictionarySearchIllustration()
            case .room:
                OnboardingImageCard(
                    imageName: "OnboardingRoomBlue"
                )
            }

            Spacer(minLength: 12)
        }
    }
}

private struct OnboardingPage: Identifiable {
    enum Visual {
        case book
        case dictionary
        case room
    }

    let id: String
    let title: String
    let subtitle: String
    let titleColor: Color
    let visual: Visual

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: "remember",
            title: "책에서 만난 단어를,\n잊지 않게.",
            subtitle: "읽다가 멈추지 마세요.\n북메이트가 기억해드릴게요.",
            titleColor: Color("Primary"),
            visual: .book
        ),
        OnboardingPage(
            id: "search",
            title: "모르는 단어,\n바로 검색하세요.",
            subtitle: "책을 읽다 막히는 순간,\n뜻을 찾고 단어장에 기록해보세요.",
            titleColor: Color("TextPrimary"),
            visual: .dictionary
        ),
        OnboardingPage(
            id: "room",
            title: "책장과 미니룸에서\n독서 기록을 모아보세요.",
            subtitle: "읽은 책과 저장한 단어가\n나만의 공간에 차곡차곡 쌓여요.",
            titleColor: Color("Primary"),
            visual: .room
        )
    ]
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

#Preview {
    OnboardingView(onFinish: {})
}
