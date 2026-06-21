//
//  AppToast.swift
//  BookMate
//
//  Created by 한채림 on 6/5/26.
//

import SwiftUI

struct AppToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: Style
    
    enum Style: Equatable {
        case success
        case error
        case info
        
        var iconName: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
        
        var tintColor: Color {
            switch self {
            case .success:
                return Color("Primary")
            case .error:
                return Color("Error")
            case .info:
                return Color("PrimaryDeep")
            }
        }
    }
}



struct AppToastView: View {
    let toast: AppToast
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.style.iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(toast.style.tintColor)
            
            Text(toast.message)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextPrimary"))
                .lineLimit(2)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color("Surface").opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color("Shadow").opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

private struct AppToastModifier: ViewModifier { // 토스트를 잠깐 띄었다가 몇 초 뒤 자동으로 사라지게 해주는 ViewModifier, content는 modifier가 붙은 원래 화면
    @Binding var toast: AppToast?
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast { // toast 값이 있으면 AppToastView를 보여주고, 없으면 아무것도 보여주지 마
                    AppToastView(toast: toast) // 원래 화면 위에 토스트가 올라감, 실제로 보이는 토스트 ui
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                } // 토스트가 위에서 부드럽게 내려오면서 나타나고, 사라질 때는 위로 올라가면서 투명해져라.
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: toast)
            .onChange(of: toast?.id) { _, newID in
                guard let newID else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { //2초 뒤에 아래 코드를 실행해줘.
                    guard toast?.id == newID else { return } // 2초 전에 예약했던 그 토스트가 아직도 현재 토스트가 맞아? 맞으면 지우고, 아니면 아무것도 안 해.
                    
                    withAnimation { // 토스트를 없애는 코드
                        toast = nil
                    }
                }
            }
    }
}

extension View {
    func appToast(_ toast: Binding<AppToast?>, duration: TimeInterval = 2.0) -> some View {
        modifier(AppToastModifier(toast: toast, duration: duration))
    }
}

#Preview("Toast") {
    ZStack {
        Color("AppBackground")
            .ignoresSafeArea()

        VStack(spacing: 16) {
            AppToastView(
                toast: AppToast(
                    message: "단어를 저장했어요.",
                    style: .success
                )
            )

            AppToastView(
                toast: AppToast(
                    message: "저장에 실패했어요.",
                    style: .error
                )
            )

            AppToastView(
                toast: AppToast(
                    message: "이미 저장한 단어예요.",
                    style: .info
                )
            )
        }
        .padding(.horizontal, 24)
    }
}

